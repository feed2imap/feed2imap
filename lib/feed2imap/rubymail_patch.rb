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

# Patches for ruby mail
# The problem is it creates a mail with multipart/mixed (= for attachments), but I need
# multipart/alternative. I just overwrite the two methods doing this.

require 'rmail'

module RMail
  class Header
    undef set_boundary
    def set_boundary(boundary)
      params = params_quoted('content-type')
      params ||= {}
      params['boundary'] = boundary
      content_type = content_type()
      content_type ||= "multipart/alternative"
      delete('Content-Type')
      add('Content-Type', content_type, nil, params)
    end
  end

  class Message
    # TODO find a way to avoid the warning. undef'ing initialize causes a warning.
    def initialize
      @header = RMail::Header.new
      @body = nil
      @epilogue = nil
      @preamble = nil
      @delimiters = nil
    end
  end
end
