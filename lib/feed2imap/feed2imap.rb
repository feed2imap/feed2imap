=begin
Feed2Imap - RSS/Atom Aggregator uploading to an IMAP Server
Copyright (c) 2005 Lucas Nussbaum <lucas@lucas-nussbaum.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
=end

# Feed2Imap version
F2I_VERSION = '0.9'

require 'feed2imap/config'
require 'feed2imap/cache'
require 'feed2imap/httpfetcher'
require 'logger'
require 'thread'
require 'feedparser'
require 'feed2imap/itemtomail'
require 'open3'

class Feed2Imap
  def Feed2Imap.version
    return F2I_VERSION
  end

  def initialize(verbose, cacherebuild, configfile)
    @logger = Logger::new(STDOUT)
    if verbose == :debug
      @logger.level = Logger::DEBUG
      require 'pp'
    elsif verbose == true
      @logger.level = Logger::INFO
    else
      @logger.level = Logger::WARN
    end
    @logger.info("Feed2Imap V.#{F2I_VERSION} started")
    # reading config
    @logger.info('Reading configuration file ...')
    if not File::exist?(configfile)
      @logger.fatal("Configuration file #{configfile} not found.")
      exit(1)
    end
    if (File::stat(configfile).mode & 044) != 0
      @logger.warn("Configuration file is readable by other users. It " +
        "probably contains your password.")
    end
    begin
      File::open(configfile) { 
        |f| @config = F2IConfig::new(f)
      }
    rescue
      @logger.fatal("Error while reading configuration file, exiting: #{$!}")
      exit(1)
    end
    if @logger.level == Logger::DEBUG
      @logger.debug("Configuration read:")
      pp(@config)
    end

    # init cache
    @logger.info('Initializing cache ...')
    @cache = ItemCache::new(@config.updateddebug)
    if not File::exist?(@config.cache + '.lock')
      f = File::new(@config.cache + '.lock', 'w')
      f.close
    end
    if File::new(@config.cache + '.lock', 'w').flock(File::LOCK_EX | File::LOCK_NB) == false
      @logger.fatal("Another instance of feed2imap is already locking the cache file")
      exit(1)
    end
    if not File::exist?(@config.cache) 
      @logger.warn("Cache file #{@config.cache} not found, using a new one")
    else
      File::open(@config.cache) do |f|
        @cache.load(f)
      end
    end

    # connecting all IMAP accounts
    @logger.info('Connecting to IMAP accounts ...')
    @config.imap_accounts.each_value do |ac|
      begin
        ac.connect
      rescue
        @logger.fatal("Error while connecting to #{ac}, exiting: #{$!}")
        exit(1)
      end
    end

    # for each feed, fetch, upload to IMAP and cache
    @logger.info("Fetching and filtering feeds ...")
    ths = []
    mutex = Mutex::new
    @config.feeds.each do |f|
      ths << Thread::new(f) do |feed|
        begin
          mutex.lock
          lastcheck = @cache.get_last_check(feed.name) 
          if feed.needfetch(lastcheck)
            mutex.unlock
            if feed.url
              s = HTTPFetcher::fetch(feed.url, @cache.get_last_check(feed.name))
            elsif feed.execurl
              s = %x{#{feed.execurl}}
            else
              @logger.warn("No way to fetch feed #{feed.name} !")
            end
            if feed.filter
              Open3::popen3(feed.filter) do |stdin, stdout|
                stdin.puts s
                stdin.close
                s = stdout.read
              end
            end
            mutex.lock
            feed.body = s
            @cache.set_last_check(feed.name, Time::now)
          else
            @logger.debug("Feed #{feed.name} doesn't need to be checked again for now.")
          end
          mutex.unlock
          # dump if requested
          if @config.dumpdir
            mutex.synchronize do
              if feed.body
                fname = @config.dumpdir + '/' + feed.name + '-' + Time::now.xmlschema
                File::open(fname, 'w') { |file| file.puts feed.body }
              end
            end
          end
          # dump this feed if requested
          if feed.dumpdir
            mutex.synchronize do
              if feed.body
                fname = feed.dumpdir + '/' + feed.name + '-' + Time::now.xmlschema
                File::open(fname, 'w') { |file| file.puts feed.body }
              end
            end
          end
        rescue Timeout::Error
          mutex.synchronize do
            n = @cache.fetch_failed(feed.name)
            m = "Timeout::Error while fetching #{feed.url}: #{$!} (failed #{n} times)"
            if n > @config.max_failures
              @logger.fatal(m)
            else
              @logger.info(m)
            end
          end
        rescue
          mutex.synchronize do
            n = @cache.fetch_failed(feed.name)
            m = "Error while fetching #{feed.url}: #{$!} (failed #{n} times)"
            if n > @config.max_failures
              @logger.fatal(m)
            else
              @logger.info(m)
            end
          end
        end
      end
    end
    ths.each { |t| t.join }
    @logger.info("Parsing and uploading ...")
    @config.feeds.each do |f|
      if f.body.nil? # means 304
        @logger.debug("Feed #{f.name} did not change.")
        next
      end
      begin
        feed = FeedParser::Feed::new(f.body)
      rescue Exception
        n = @cache.parse_failed(f.name)
        m = "Error while parsing #{f.name}: #{$!} (failed #{n} times)"
        if n > @config.max_failures
          @logger.fatal(m)
        else
          @logger.info(m)
        end
        next
      end
      begin
        newitems, updateditems = @cache.get_new_items(f.name, feed.items, f.always_new, f.ignore_hash)
      rescue
        @logger.fatal("Exception caught when selecting new items for #{f.name}: #{$!}")
        puts $!.backtrace
        next
      end
      @logger.info("#{f.name}: #{newitems.length} new items, #{updateditems.length} updated items.") if newitems.length > 0 or updateditems.length > 0 or @logger.level == Logger::DEBUG
      begin
        if !cacherebuild
          updateditems.each do |i|
            email = item_to_mail(i, i.cacheditem.index, true, f.name)
            f.imapaccount.updatemail(f.folder, email,
                                     i.cacheditem.index, i.date || Time::new)
          end
          newitems.each do |i|
            email = item_to_mail(i, i.cacheditem.index, false, f.name)
            f.imapaccount.putmail(f.folder, email, i.date || Time::new)
          end
        end
      rescue
        @logger.fatal("Exception caught while uploading mail to #{f.folder}: #{$!}")
        puts $!.backtrace
        next
      end
      begin
        @cache.commit_cache(f.name)
      rescue
        @logger.fatal("Exception caught while updating cache for #{f.name}: #{$!}")
        next
      end
    end
    @logger.info("Finished. Saving cache ...")
    begin
      File::open(@config.cache, 'w') { |f| @cache.save(f) }
    rescue
      @logger.fatal("Exception caught while writing cache to #{@config.cache}: #{$!}")
    end
    @logger.info("Closing IMAP connections ...")
    @config.imap_accounts.each_value do |ac|
      begin
        ac.disconnect
      rescue
        # servers tend to cause an exception to be raised here, hence the INFO level.
        @logger.info("Exception caught while closing connection to #{ac.to_s}: #{$!}")
      end
    end
  end
end
