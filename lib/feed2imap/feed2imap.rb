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

F2I_WARNFETCHTIME = 10

require 'feed2imap/version'
require 'feed2imap/config'
require 'feed2imap/cache'
require 'feed2imap/httpfetcher'
require 'logger'
require 'thread'
require 'feedparser'
require 'feed2imap/rexml_settings'
require 'feed2imap/itemtomail'
require 'open3'

class Feed2Imap
  def Feed2Imap.version
    return Feed2Imap::VERSION
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
    @logger.info("Feed2Imap V.#{Feed2Imap::VERSION} started")
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
    sparefetchers = 16 # max number of fetchers running at the same time.
    sparefetchers_mutex = Mutex::new
    sparefetchers_cond = ConditionVariable::new
    @config.feeds.each do |f|
      ths << Thread::new(f) do |feed|
        begin
          mutex.lock
          lastcheck = @cache.get_last_check(feed.name) 
          if feed.needfetch(lastcheck)
            mutex.unlock
            sparefetchers_mutex.synchronize do
              while sparefetchers <= 0
                sparefetchers_cond.wait(sparefetchers_mutex)
              end
              sparefetchers -= 1
            end
            fetch_start = Time::now
            if feed.url
              fetcher = HTTPFetcher::new
              fetcher::timeout = @config.timeout
              s = fetcher::fetch(feed.url, @cache.get_last_check(feed.name))
            elsif feed.execurl
              # avoid running more than one command at the same time.
              # We need it because the called command might not be
              # thread-safe, and we need to get the right exitcode
              mutex.lock
              s = %x{#{feed.execurl}}
              if $? && $?.exitstatus != 0
                @logger.warn("Command for #{feed.name} exited with status #{$?.exitstatus} !")
              end
              mutex.unlock
            else
              @logger.warn("No way to fetch feed #{feed.name} !")
            end
            if feed.filter and s != nil
              # avoid running more than one command at the same time.
              # We need it because the called command might not be
              # thread-safe, and we need to get the right exitcode.
              mutex.lock
              # hack hack hack, avoid buffering problems
              begin
                stdin, stdout, stderr = Open3::popen3(feed.filter)
                inth = Thread::new do
                  stdin.puts s
                  stdin.close
                end
                output = nil
                outh = Thread::new do
                  output = stdout.read
                end
                inth.join
                outh.join
                s = output
                if $? && $?.exitstatus != 0
                  @logger.warn("Filter command for #{feed.name} exited with status #{$?.exitstatus}. Output might be corrupted !")
                end
              ensure
                mutex.unlock
              end
            end
            if Time::now - fetch_start > F2I_WARNFETCHTIME
              @logger.info("Fetching feed #{feed.name} took #{(Time::now - fetch_start).to_i}s")
            end
            sparefetchers_mutex.synchronize do
              sparefetchers += 1
              sparefetchers_cond.signal
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
        feed = FeedParser::Feed::new(f.body.force_encoding('UTF-8'), f.url)
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
          fn = f.name.gsub(/[^0-9A-Za-z]/,'')
          updateditems.each do |i|
            id = "<#{fn}-#{i.cacheditem.index}@#{@config.hostname}>"
            email = item_to_mail(@config, i, id, true, f.name, f.include_images, f.wrapto)
            f.imapaccount.updatemail(f.folder, email,
                                     id, i.date || Time::new, f.reupload_if_updated)
          end
          # reverse is needed to upload older items first (fixes gna#8986)
          newitems.reverse.each do |i|
            id = "<#{fn}-#{i.cacheditem.index}@#{@config.hostname}>"
            email = item_to_mail(@config, i, id, false, f.name, f.include_images, f.wrapto)
            f.imapaccount.putmail(f.folder, email, i.date || Time::new)
          end
        end
      rescue
        @logger.fatal("Exception caught while uploading mail to #{f.folder}: #{$!}")
        puts $!.backtrace
        @logger.fatal("We can't recover from IMAP errors, so we are exiting.")
        exit(1)
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
      File::open("#{@config.cache}.new", 'w') { |f| @cache.save(f) }
    rescue
      @logger.fatal("Exception caught while writing new cache to #{@config.cache}.new: #{$!}")
    end
    begin
      File::rename("#{@config.cache}.new", @config.cache)
    rescue
      @logger.fatal("Exception caught while renaming #{@config.cache}.new to #{@config.cache}: #{$!}")
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
