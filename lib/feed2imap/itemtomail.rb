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
require 'rmail'
require 'digest/md5'

class String
  def needMIME
    utf8 = false
    begin
      self.unpack('U*').each do |c|
        if c > 127
          utf8 = true
          break
        end
      end
    rescue
      # safe fallback in case of problems
      utf8 = true
    end
    utf8
  end
end

def item_to_mail(item, index, updated, from = 'Feed2Imap', inline_images = false)
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
  if item.date.nil?
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
  textpart.header['Content-Transfer-Encoding'] = '8bit'
  textpart.body = item.to_text
  htmlpart = RMail::Message::new
  htmlpart.header['Content-Type'] = 'text/html; charset=utf-8'
  htmlpart.header['Content-Transfer-Encoding'] = '8bit'
  htmlpart.body = item.to_html

  # inline images as attachments
  if inline_images
    message.header.set('Content-Type', 'multipart/related', 'type'=> 'multipart/alternative')
    texthtml = RMail::Message::new
    texthtml.header.set('Content-Type', 'multipart/alternative')
    texthtml.add_part(textpart)
    texthtml.add_part(htmlpart)
    message.add_part(texthtml)

    htmlpart.body.gsub!(/(<img[^>]+)src="(\S+?\/([^\/]+?\.(png|gif|jpe?g)))"([^>]*>)/i) do |match|
      # $2 contains url, $3 the image name, $4 the image extension
      begin
        image = Base64.encode64(HTTPFetcher::fetch($2, Time.at(0)).chomp) + "\n"
        cid = "#{Digest::MD5.hexdigest($2)}@feed2imap.acme.com"
        imgpart = RMail::Message.new
        imgpart.header.set('Content-ID', "<#{cid}>")
        type = $4
        type = 'jpeg' if type.downcase == 'jpg' # hack hack hack
        imgpart.header.set('Content-Type', "image/#{type}", 'name' => $3)
        imgpart.header.set('Content-Disposition', 'attachment', 'filename' => $3)
        imgpart.header.set('Content-Transfer-Encoding', 'base64')
        imgpart.body = image
        message.add_part(imgpart)
        # now to specify what to replace with
        newtag = "#{$1}src=\"cid:#{cid}\"#{$5}"
        print "#{cid}: Replacing '#{$&}' with '#{newtag}'...\n"
        newtag
      rescue
        print "Error while fetching image #{$2}: #{$!}...\n"
        $& # don't modify on exception
      end
    end
  else
    message.header['Content-Type'] = 'multipart/alternative'
    message.add_part(textpart)
    message.add_part(htmlpart)
  end
  return message.to_s
end

