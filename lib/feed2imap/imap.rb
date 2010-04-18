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

  @@no_ssl_verify = false
  def ImapAccount::no_ssl_verify=(v)
    @@no_ssl_verify = v
  end

  def initialize(uri)
    @uri = uri
    @existing_folders = []
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
    @connection = Net::IMAP::new(uri.host, port, usessl, nil, !@@no_ssl_verify)
    user, password = URI::unescape(uri.userinfo).split(':',2)
    @connection.login(user, password)
    self
  end

  # disconnect from the IMAP server
  def disconnect
    if @connection
      @connection.logout
      @connection.disconnect
    end
  end

  # tests if the folder exists and create it if not
  def create_folder_if_not_exists(folder)
    return if @existing_folders.include?(folder)
    if @connection.list('', folder).nil?
      @connection.create(folder)
      @connection.subscribe(folder)
    end
    @existing_folders << folder
  end

  # Put the mail in the given folder
  # You should check whether the folder exist first.
  def putmail(folder, mail, date = Time::now)
    create_folder_if_not_exists(folder)
    @connection.append(folder, mail.gsub(/\n/, "\r\n"), nil, date)
  end

  # update a mail
  def updatemail(folder, mail, id, date = Time::now)
    create_folder_if_not_exists(folder)
    @connection.select(folder)
    searchres = @connection.search(['HEADER', 'Message-Id', id])
    flags = nil
    if searchres.length > 0
      # we get the flags from the first result and delete everything
      flags = @connection.fetch(searchres[0], 'FLAGS')[0].attr['FLAGS']
      searchres.each { |m| @connection.store(m, "+FLAGS", [:Deleted]) }
      @connection.expunge
      flags -= [ :Recent ] # avoids errors with dovecot
    end
    @connection.append(folder, mail.gsub(/\n/, "\r\n"), flags, date)
  end

  # convert to string
  def to_s
    u2 = uri.clone
    u2.password = 'PASSWORD'
    u2.to_s
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

