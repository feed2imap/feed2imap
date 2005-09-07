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

require 'feed2imap/sgml-parser'

# this class provides a simple SGML parser that removes HTML tags
class HTML2TextParser < SGMLParser

  attr_reader :savedata

  def initialize(verbose = false)
    @savedata = ''
    @pre = false
    @href = nil
    @links = []
    super(verbose)
  end

  def handle_data(data)
    # let's remove all CR
    data.gsub!(/\n/, '') if not @pre
 
    @savedata << data
  end

  def unknown_starttag(tag, attrs)
    case tag
    when 'p'
      @savedata << "\n\n"
    when 'br'
      @savedata << "\n"
    when 'b'
      @savedata << '*'
    when 'u'
      @savedata << '_'
    when 'i'
      @savedata << '/'
    when 'pre'
      @savedata << "\n\n"
      @pre = true
    when 'a'
      # find href in args
      @href = nil
      attrs.each do |a|
        if a[0] == 'href'
          @href = a[1]
        end
      end
      if @href
        @links << @href.gsub(/^("|'|)(.*)("|')$/,'\2')
      end
    end
  end

  def close
    super
    if @links.length > 0
      @savedata << "\n\n"
      @links.each_index do |i|
        @savedata << "[#{i+1}] #{@links[i]}\n"
      end
    end
  end

  def unknown_endtag(tag)
    case tag
    when 'b'
      @savedata << '*'
    when 'u'
      @savedata << '_'
    when 'i'
      @savedata << '/'
    when 'pre'
      @savedata << "\n\n"
      @pre = false
    when 'a'
      if @href
        @savedata << "[#{@links.length}]"
        @href = nil
      end
    end
  end
end
