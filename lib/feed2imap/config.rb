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
require 'feed2imap/maildir'
require 'etc'
require 'socket'

# Default cache file
DEFCACHE = ENV['HOME'] + '/.feed2imap.cache'

# Hostname and login name of the current user
HOSTNAME = Socket.gethostname
LOGNAME = Etc.getlogin

# Feed2imap configuration
class F2IConfig
  attr_reader :imap_accounts, :cache, :feeds, :dumpdir, :updateddebug, :max_failures, :include_images, :default_email, :hostname, :reupload_if_updated

  # Load the configuration from the IO stream
  # TODO should do some sanity check on the data read.
  def initialize(io)
    @conf = YAML::load(io)
    @cache = @conf['cache'] || DEFCACHE
    @dumpdir = @conf['dumpdir'] || nil
    @conf['feeds'] ||= []
    @feeds = []
    @max_failures = (@conf['max-failures'] || 10).to_i

    @updateddebug = false
    @updateddebug = @conf['debug-updated'] if @conf.has_key?('debug-updated')

    @include_images = true
    @include_images = @conf['include-images'] if @conf.has_key?('include-images')

    @reupload_if_updated = true
    @reupload_if_updated = @conf['reupload-if-updated'] if @conf.has_key?('reupload-if-updated')

    @default_email = (@conf['default-email'] || "#{LOGNAME}@#{HOSTNAME}")
    ImapAccount.no_ssl_verify = (@conf.has_key?('disable-ssl-verification') and @conf['disable-ssl-verification'] == true)
    @hostname = HOSTNAME # FIXME: should this be configurable as well?
    @imap_accounts = ImapAccounts::new
    maildir_account = MaildirAccount::new
    @conf['feeds'].each do |f|
      if f['disable'].nil?
        uri = URI::parse(f['target'].to_s)
        path = URI::unescape(uri.path)
        path = path[1..-1] if path[0,1] == '/'
        if uri.scheme == 'maildir'
          @feeds.push(ConfigFeed::new(f, maildir_account, path, self))
        else
          @feeds.push(ConfigFeed::new(f, @imap_accounts.add_account(uri), path, self))
        end
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
  attr_reader :name, :url, :imapaccount, :folder, :always_new, :execurl, :filter, :ignore_hash, :dumpdir, :wrapto, :include_images, :reupload_if_updated
  attr_accessor :body

  def initialize(f, imapaccount, folder, f2iconfig)
    @name = f['name']
    @url = f['url']
    @url.sub!(/^feed:/, '') if @url =~ /^feed:/
    @imapaccount = imapaccount
    @folder = encode_utf7 folder
    @freq = f['min-frequency']

    @always_new = false
    @always_new = f['always-new'] if f.has_key?('always-new')

    @execurl = f['execurl']
    @filter = f['filter']

    @ignore_hash = false
    @ignore_hash = f['ignore-hash'] if f.has_key?('ignore-hash')

    @freq = @freq.to_i if @freq
    @dumpdir = f['dumpdir'] || nil
    @wrapto = if f['wrapto'] == nil then 72 else f['wrapto'].to_i end

    @include_images = f2iconfig.include_images
    @include_images = f['include-images'] if f.has_key?('include-images')

    @reupload_if_updated = f2iconfig.reupload_if_updated
    @reupload_if_updated = f['reupload-if-updated'] if f.has_key?('reupload-if-updated')
  end

  def needfetch(lastcheck)
    return true if @freq.nil?
    return (lastcheck + @freq * 3600) < Time::now
  end

  def encode_utf7(s)
    if "foo".respond_to?(:force_encoding)
      return Net::IMAP::encode_utf7 s
    else
      # this is a copy of the Net::IMAP::encode_utf7 w/o the force_encoding
      return s.gsub(/(&)|([^\x20-\x7e]+)/u) {
        if $1
          "&-"
        else
          base64 = [$&.unpack("U*").pack("n*")].pack("m")
          "&" + base64.delete("=\n").tr("/", ",") + "-"
        end }
    end
  end
end
