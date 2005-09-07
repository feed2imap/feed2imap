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

# Imap connection handling
require 'feed2imap/rubyimap'
begin
require 'openssl'
rescue LoadError
end
require 'uri'

# This class is a container of IMAP accounts.
# Thanks to it, accounts are re-used : several feeds
# using the same IMAP account will create only one
# IMAP connection.
class ImapAccounts < Hash
  def add_account(uri)
    u = URI::Generic::build({ :scheme => uri.scheme,
                              :userinfo => uri.userinfo,
                              :host => uri.host,
                              :port => uri.port })
    if not include?(u)
      ac = ImapAccount::new(u)
      self[u] = ac
    end
    return self[u]
  end
end

# This class is an IMAP account, with the given fd
# once the connection has been established
class ImapAccount
  attr_reader :uri

  def initialize(uri)
    @uri = uri
    self
  end

  # connects to the IMAP server
  # raises an exception if it fails
  def connect
    port = 143
    usessl = false
    if uri.scheme == 'imap'
      port = 143
      usessl = false
    elsif uri.scheme == 'imaps'
      port = 993
      usessl = true
    else
      raise "Unknown scheme: #{uri.scheme}"
    end
    # use given port if port given
    port = uri.port if uri.port 
    @connection = Net::IMAP::new(uri.host, port, usessl)
    user, password = URI::unescape(uri.userinfo).split(':',2)
    @connection.login(user, password)
    self
  end

  # disconnect from the IMAP server
  def disconnect
    @connection.disconnect if @connection
  end

  # Returns true if the folder exist
  def folder_exist?(folder)
    return !@connection.list('', folder).nil?
  end

  # Creates the given folder
  def create_folder(folder)
    @connection.create(folder)
    @connection.subscribe(folder)
    self
  end

  # Put the mail in the given folder
  # You should check whether the folder exist first.
  def putmail(folder, mail)
    @connection.append(folder, mail)
  end

  # update a mail
  def updatemail(folder, mail, idx)
    @connection.select(folder)
    searchres = @connection.search(['HEADER', 'X-CacheIndex', "-#{idx}-"])
    flags = nil
    if searchres.length > 0
      # we get the flags from the first result and delete everything
      flags = @connection.fetch(searchres[0], 'FLAGS')[0].attr['FLAGS']
      searchres.each { |m| @connection.store(m, "+FLAGS", [:Deleted]) }
      @connection.expunge
    end
    @connection.append(folder, mail, flags)
  end

  # convert to string
  def to_s
    uri.to_s
  end

  # remove mails in a folder according to a criteria
  def cleanup(folder, dryrun = false)
    puts "-- Considering #{folder}:"
    @connection.select(folder)
    a = ['SEEN', 'NOT', 'FLAGGED', 'BEFORE', (Date::today - 3).strftime('%d-%b-%Y')]
    todel = @connection.search(a)
    todel.each do |m|
      f = @connection.fetch(m, "FULL")
      d = f[0].attr['INTERNALDATE']
      s = f[0].attr['ENVELOPE'].subject
      if s =~ /^=\?utf-8\?b\?/
        s = Base64::decode64(s.gsub(/^=\?utf-8\?b\?(.*)\?=$/, '\1')).toISO_8859_1('utf-8')
      end
      if dryrun
        puts "To remove: #{s} (#{d})"
      else
        puts "Removing: #{s} (#{d})"
        @connection.store(m, "+FLAGS", [:Deleted])
      end
    end
    puts "-- Deleted #{todel.length} messages."
    if not dryrun
      @connection.expunge
    end
    return todel.length
  end
end

