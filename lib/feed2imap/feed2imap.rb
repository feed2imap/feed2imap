#!/usr/bin/ruby

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

require 'feed2imap/config'
require 'feed2imap/cache'
require 'feed2imap/channel'
require 'feed2imap/httpfetcher'
require 'logger'

# Feed2Imap version
F2I_VERSION = '0.2'

class Feed2Imap
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
    # for each feed, fetch, upload to IMAP and cache
    @config.feeds.each do |f|
      @logger.info("Processing #{f.url}")
      begin
        # check that folder exist
        f.imapaccount.create_folder(f.folder) if not f.imapaccount.folder_exist?(f.folder)
      rescue
        @logger.fatal("Error while creating IMAP folder #{f.folder}: #{$!}")
        exit(1)
      end
      begin
        body = HTTPFetcher::fetch(f.url, @cache.get_last_check(f.name))
        # dump if requested
        if @config.dumpdir
          fname = @config.dumpdir + '/' + f.name + '-' + Time::now.xmlschema
          File::open(fname, 'w') { |file| file.puts body }
        end
      rescue Timeout::Error
        @logger.fatal("Timeout::Error while fetching #{f.url}: #{$!}")
        next
      rescue
        @logger.fatal("Error while fetching #{f.url}: #{$!}")
        next
      end
      next if body.nil? # means 304
      begin
        channel = Channel::new(body)
      rescue
        @logger.fatal("Error while parsing #{f.url}: #{$!}")
        next
      end
      begin
        newitems, updateditems = @cache.get_new_items(f.name, channel.items)
      rescue
        @logger.fatal("Exception caught when selecting new items for #{f.url}: #{$!}")
        puts $!.backtrace
        next
      end
      @logger.info("#{newitems.length} new items, #{updateditems.length} updated items.") if newitems.length > 0 or updateditems.length > 0
      begin
        if !cacherebuild
          updateditems.each { |i| f.imapaccount.updatemail(f.folder, i.to_mail(f.name), i.cacheditem.index) }
          newitems.each { |i| f.imapaccount.putmail(f.folder, i.to_mail(f.name)) }
        end
      rescue
        @logger.fatal("Exception caught while uploading mail to #{f.folder}: #{$!}")
        next
      end
      begin
        @cache.update_cache(f.name, channel.items)
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
    begin
      @config.imap_accounts.each_value { |ac| ac.disconnect }
    rescue
      @logger.fatal("Exception caught while closing connection to #{ac.to_s}: #{$!}")
    end
  end
end
