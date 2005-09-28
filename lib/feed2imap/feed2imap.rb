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
F2I_VERSION = '0.5'

require 'feed2imap/config'
require 'feed2imap/cache'
require 'feed2imap/channel'
require 'feed2imap/httpfetcher'
require 'logger'
require 'thread'

class Feed2Imap
  def Feed2Imap.version
    return F2I_VERSION
  end

  def initialize(verbose, cacherebuild, configfile)
    @logger = Logger::new(STDOUT)
    if verbose
      @logger.level = Logger::DEBUG
    else
      @logger.level = Logger::WARN
    end
    @logger.info("Feed2Imap V.#{F2I_VERSION} started")
    # reading config
    @logger.info('Reading configuration file')
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
    # init cache
    @logger.info('Initializing cache')
    @cache = ItemCache::new
    if not File::exist?(@config.cache) 
      @logger.warn("Cache file #{@config.cache} not found, using a new one")
    else
      File::open(@config.cache) { |f| @cache.load(f) }
    end
    # connecting all IMAP accounts
    @logger.info('Connecting to IMAP accounts')
    @config.imap_accounts.each_value do |ac|
      begin
        ac.connect
      rescue
        @logger.fatal("Error while connecting to #{ac}, exiting: #{$!}")
        exit(1)
      end
    end
    # check that IMAP folders exist
    @logger.info("Checking IMAP folders")
    @config.feeds.each do |f|
      begin
        f.imapaccount.create_folder(f.folder) if not f.imapaccount.folder_exist?(f.folder)
      rescue
        @logger.fatal("Error while creating IMAP folder #{f.folder}: #{$!}")
        exit(1)
      end
    end
    # for each feed, fetch, upload to IMAP and cache
    @logger.info("Fetching feeds")
    loggermon = Mutex::new
    ths = []
    @config.feeds.each do |f|
      ths << Thread::new do
        begin
          lastcheck = @cache.get_last_check(f.name) 
          if f.needfetch(lastcheck)
            f.body = HTTPFetcher::fetch(f.url, @cache.get_last_check(f.name))
            @cache.set_last_check(f.name, Time::now)
          end
          # dump if requested
          if @config.dumpdir and f.body
            fname = @config.dumpdir + '/' + f.name + '-' + Time::now.xmlschema
            File::open(fname, 'w') { |file| file.puts f.body }
          end
        rescue Timeout::Error
          loggermon.synchronize do
            @logger.fatal("Timeout::Error while fetching #{f.url}: #{$!}")
          end
        rescue
          loggermon.synchronize do
            @logger.fatal("Error while fetching #{f.url}: #{$!}")
          end
        end
      end
    end
    ths.each { |t| t.join }
    @logger.info("Parsing and uploading")
    @config.feeds.each do |f|
      next if f.body.nil? # means 304
      begin
        channel = Channel::new(f.body)
      rescue Exception => e
        @logger.fatal("Error while parsing #{f.name}: #{e}")
        next
      end
      begin
        newitems, updateditems = @cache.get_new_items(f.name, channel.items)
      rescue
        @logger.fatal("Exception caught when selecting new items for #{f.name}: #{$!}")
        puts $!.backtrace
        next
      end
      @logger.info("#{f.name}: #{newitems.length} new items, #{updateditems.length} updated items.") if newitems.length > 0 or updateditems.length > 0
      begin
        if !cacherebuild
          updateditems.each { |i| f.imapaccount.updatemail(f.folder, i.to_mail(f.name), i.cacheditem.index) }
          newitems.each { |i| f.imapaccount.putmail(f.folder, i.to_mail(f.name)) }
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
    @logger.info("Finished. Saving cache")
    begin
      File::open(@config.cache, 'w') { |f| @cache.save(f) }
    rescue
      @logger.fatal("Exception caught while writing cache to #{@config.cache}: #{$!}")
    end
    @logger.info("Closing IMAP connections")
    @config.imap_accounts.each_value do |ac|
      begin
        ac.disconnect
      rescue
        @logger.fatal("Exception caught while closing connection to #{ac.to_s}: #{$!}")
      end
    end
  end
end
