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
require 'mail'
require 'feedparser'
require 'feedparser/text-output'
require 'feedparser/html-output'
require 'base64'
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

def item_to_mail(config, item, id, updated, from = 'Feed2Imap', inline_images = false, wrapto = false)
  message = Mail::new do
    message_id id
    to      "#{from} <#{config.default_email}>"
    from    (
      if item.creator and item.creator != ''
        if item.creator.include?('@')
          item.creator.chomp
        else
          "#{item.creator.chomp} <#{config.default_email}>"
        end
      else
        "#{from} <#{config.default_email}>"
      end
    )

    date    item.date unless item.date.nil?

    subject item.title or (item.date and item.date.to_s) or item.link
    transport_encoding '8bit'
  end

  message['X-Feed2Imap-Version'] = F2I_VERSION if defined?(F2I_VERSION)
  message['X-F2IStatus'] = 'Updated' if updated


  textpart = htmlpart = nil
  parts = config.parts
  if parts.include?('text')
    textpart = Mail::Part.new do
        content_type 'text/plain; charset=utf-8; format=flowed'
        content_transfer_encoding '8bit'
        body item.to_text(true, wrapto, false)
    end
  end
  if parts.include?('html')
    htmlpart = Mail::Part.new do
        content_type 'text/html; charset=utf-8'
        content_transfer_encoding '8bit'
        body item.to_html
    end
  end

  # inline images as attachments
  if inline_images
    fetcher = HTTPFetcher.new
    html = htmlpart.body.decoded
    html.gsub!(/(<img[^>]+)src="(\S+?\/([^\/]+?\.(png|gif|jpe?g)))"([^>]*>)/i) do |match|
      # $2 contains url, $3 the image name, $4 the image extension
      begin
        if $2.include? " "
            url = URI::escape $2
        else
            url = $2
        end
        image = Base64.encode64(fetcher.fetch(url, Time.at(0)).chomp)
        "#{$1}src=\"data:image/#{$4};base64,#{image}\"#{$5}"
      rescue
        @logger.error "Error while fetching image #{$2}: #{$!}..."
        $& # don't modify on exception
      end
    end
    htmlpart.body = html
  end
  
  # textpart/htmlpart are nil when not set
  # Mail then ignores them if nil; if both are given it sets multipart/alternative
  message.text_part = textpart
  message.html_part = htmlpart
  
  return message.to_s
end
