=begin
Feed2Imap - RSS/Atom Aggregator uploading to an IMAP Server
Copyright (c) 2005 Lucas Nussbaum <lucas@lucas-nussbaum.net>

This file contains classes to parse a feed and store it as a Channel object.

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

require 'rexml/document'
require 'time'
require 'rmail'
require 'feedparser'
require 'feedparser/text-output'
require 'feedparser/html-output'
require 'base64'
require 'feed2imap/rubymail_patch'

class String
  def needMIME
    utf8 = false
    self.unpack('U*').each do |c|
      if c > 127
        utf8 = true
        break
      end
    end
    utf8
  end
end

def item_to_mail(item, index, updated, from = 'Feed2Imap')
  message = RMail::Message::new
  if item.creator and item.creator != ''
    if item.creator.include?('@')
      message.header['From'] = item.creator.chomp
    else
      message.header['From'] = "#{item.creator.chomp} <feed2imap@acme.com>"
    end
  else
    message.header['From'] = "#{from} <feed2imap@acme.com>"
  end
  message.header['To'] = "#{from} <feed2imap@acme.com>"
  if @date.nil?
    message.header['Date'] = Time::new.rfc2822
  else
    message.header['Date'] = item.date.rfc2822
  end
  message.header['X-Feed2Imap-Version'] = F2I_VERSION if defined?(F2I_VERSION)
  message.header['X-CacheIndex'] = "-#{index}-"
  message.header['X-F2IStatus'] = "Updated" if updated
  # treat subject. Might need MIME encoding.
  subj = item.title or (item.date and item.date.to_s) or item.link
  if subj
    if subj.needMIME
      message.header['Subject'] = "=?utf-8?b?#{Base64::encode64(subj).gsub("\n",'')}?="
    else
      message.header['Subject'] = subj 
    end
  end
  textpart = RMail::Message::new
  textpart.header['Content-Type'] = 'text/plain; charset=utf-8'
  textpart.header['Content-Transfer-Encoding'] = '7bit'
  textpart.body = item.to_text
  htmlpart = RMail::Message::new
  htmlpart.header['Content-Type'] = 'text/html; charset=utf-8'
  htmlpart.header['Content-Transfer-Encoding'] = '7bit'
  htmlpart.body = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"><html><body>' + item.to_html + '</body></html>'
  message.add_part(textpart)
  message.add_part(htmlpart)
  return message.to_s
end

