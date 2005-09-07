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

# for URI::regexp
require 'uri'
require 'feed2imap/html2text-parser'

# This class provides various converters
class String
  # is this text HTML ? search for tags
  def html?
    return (self =~ /<p>/) || (self =~ /<br>/) || (self =~ /<br\s*(\/)?\s*>/)
  end

  # returns true if the text contains escaped HTML (with HTML entities)
  def escaped_html?
    return (self =~ /&lt;img src=/) || (self =~ /&lt;a href=/) || (self =~ /&lt;br(\/| \/|)&gt;/)
  end

  # un-escape HTML in the text
  def unescape_html
    {
      '<' => '&lt;',
      '>' => '&gt;',
      "'" => '&apos;',
      '"' => '&quot;',
      '&' => '&amp;',
      "\047" => '&#39;'
    }.each do |k, v|
      gsub!(v, k)
    end
    self
  end

  # convert text to HTML
  def text2html
    text = self.clone
    return text if text.html?
    if text.escaped_html?
      return text.unescape_html
    end
    # paragraphs
    text.gsub!(/\A\s*(.*)\Z/m, '<p>\1</p>')
    text.gsub!(/\s*\n(\s*\n)+\s*/, "</p>\n<p>")
    # uris
    text.gsub!(/(#{URI::regexp(['http','ftp','https'])})/,
        '<a href="\1">\1</a>')
    text
  end

  # Convert an HTML text to plain text
  def html2text
    if false
      text = self.clone
      # let's remove all CR
      text.gsub!(/\n/, '')
      # convert <p> and <br>
      text.gsub!(/\s*<\/p>\s*/, '')
      text.gsub!(/\s*<p(\s[^>]*)?>\s*/, "\n\n")
      text.gsub!(/\s*<br(\s*)\/?(\s*)>\s*/, "\n")
      # remove other tags
      text.gsub!(/<[^>]*>/, '')
      # remove leading and trailing whilespace
      text.gsub!(/\A\s*/m, '')
      text.gsub!(/\s*\Z/m, '')
      text
    else
      text = self.clone
      # parse HTML
      p = HTML2TextParser::new(true)
      p.feed(text)
      p.close
      text = p.savedata
      # remove leading and trailing whilespace
      text.gsub!(/\A\s*/m, '')
      text.gsub!(/\s*\Z/m, '')
      # remove whitespace around \n
      text.gsub!(/ *\n/m, "\n")
      text.gsub!(/\n */m, "\n")
      # and duplicates \n
      text.gsub!(/\n\n+/m, "\n\n")
      text
    end
  end

  # Remove white space around the text
  def rmWhiteSpace!
    return self.gsub!(/\A\s*/m, '').gsub!(/\s*\Z/m,'')
  end

  # Convert a text in inputenc to a text in ISO-8859-1
  def toISO_8859_1(inputenc)
    if inputenc.downcase == 'utf-8'
      begin
        return self.unpack('U*').pack('C*')
      rescue
        return self
      end
    else
      return self
    end
  end

  # Convert a text in inputenc to a text in UTF8
  # must take care of wrong input locales
  def toUTF8(inputenc)
    if inputenc.downcase != 'utf-8'
      # it is said it is not UTF-8. Ensure it is REALLY not UTF-8
      begin
        if self.unpack('U*').pack('U*') == self
          return self
        end
      rescue
        # do nothing
      end
      begin
        return self.unpack('C*').pack('U*')
      rescue
        return self #failsafe solution. but a dirty one :-)
      end
    else
      return self
    end
  end

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
