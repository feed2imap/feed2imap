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

require 'yaml'
require 'uri'
require 'feed2imap/imap'

# Default cache file
DEFCACHE = ENV['HOME'] + '/.feed2imap.cache'

# Feed2imap configuration
class F2IConfig
  attr_reader :imap_accounts, :cache, :feeds, :dumpdir, :updateddebug, :max_failures, :include_images

  # Load the configuration from the IO stream
  # TODO should do some sanity check on the data read.
  def initialize(io)
    @conf = YAML::load(io)
    @cache = @conf['cache'] || DEFCACHE
    @dumpdir = @conf['dumpdir'] || nil
    @conf['feeds'] ||= []
    @feeds = []
    @max_failures = (@conf['max-failures'] || 10).to_i
    @updateddebug =  (@conf['debug-updated'] and @conf['debug-updated'] != 'false')
    @include_images = (@conf['include-images'] and @conf['include-images'] != 'false')
    @imap_accounts = ImapAccounts::new
    @conf['feeds'].each do |f|
      if f['disable'].nil?
        uri = URI::parse(f['target'])
        path = URI::unescape(uri.path)
        path = path[1..-1] if path[0,1] == '/'
        @feeds.push(ConfigFeed::new(f, @imap_accounts.add_account(uri), path, self))
      end
    end
  end

  def to_s
    s =  "Your Feed2Imap config :\n"
    s += "=======================\n"
    s += "Cache file: #{@cache}\n\n"
    s += "Imap accounts I'll have to connect to :\n"
    s += "---------------------------------------\n"
    @imap_accounts.each_value { |i| s += i.to_s + "\n" }
    s += "\nFeeds :\n"
    s +=   "-------\n"
    i = 1
    @feeds.each do |f|
      s += "#{i}. #{f.name}\n"
      s += "    URL: #{f.url}\n"
      s += "    IMAP Account: #{f.imapaccount}\n"
      s += "    Folder: #{f.folder}\n"

      if not f.wrapto
        s += "    Not wrapped.\n"
      end

      s += "\n"
      i += 1
    end
    s
  end
end

# A configured feed. simple data container.
class ConfigFeed
  attr_reader :name, :url, :imapaccount, :folder, :always_new, :execurl, :filter, :ignore_hash, :dumpdir, :wrapto, :include_images
  attr_accessor :body

  def initialize(f, imapaccount, folder, f2iconfig)
    @name = f['name']
    @url = f['url']
    @url.sub!(/^feed:/, '') if @url =~ /^feed:/
    @imapaccount, @folder = imapaccount, folder
    @freq = f['min-frequency']
    @always_new =  (f['always-new'] and f['always-new'] != 'false')
    @execurl = f['execurl']
    @filter = f['filter']
    @ignore_hash = f['ignore-hash'] || false
    @freq = @freq.to_i if @freq
    @dumpdir = f['dumpdir'] || nil
    @wrapto = if f['wrapto'] == nil then 72 else f['wrapto'].to_i end
    @include_images = f2iconfig.include_images
    if f['include-images']
       @include_images = (f['include-images'] != 'false')
    end
  end

  def needfetch(lastcheck)
    return true if @freq.nil?
    return (lastcheck + @freq * 3600) < Time::now
  end
end
