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

require 'feedparser'

# Patch for REXML
# Very ugly patch to make REXML error-proof.
# The problem is REXML uses IConv, which isn't error-proof at all.
# With those changes, it uses unpack/pack with some error handling
module REXML
  module Encoding
    def decode(str)
      return str.toUTF8(@encoding)
    end

    def encode(str)
      return str
    end

    def encoding=(enc)
      return if defined? @encoding and enc == @encoding
      @encoding = enc || 'utf-8'
    end
  end

  class Element
    def children
      @children
    end
  end
end
