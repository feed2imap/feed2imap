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

# This class manages a cache of items
# (items which have already been seen)

require 'digest/md5'

class ItemCache
  def initialize
    @channels = {}
    @@cacheidx = 0
    self
  end

  # Returns the really new items amongst items
  def get_new_items(id, items)
    @channels[id] ||= CachedChannel::new
    return @channels[id].get_new_items(items)
  end

  # Replace the existing cached items by those ones
  def update_cache(id, items)
    @channels[id] ||= CachedChannel::new
    @channels[id].update(items)
  end

  # Get the last time the cache was updated
  def get_last_check(id)
    @channels[id] ||= CachedChannel::new
    @channels[id].lastcheck
  end

  # Get the last time the cache was updated
  def set_last_check(id, time)
    @channels[id] ||= CachedChannel::new
    @channels[id].lastcheck = time
    self
  end

  # Load the cache from an IO stream
  def load(io)
    begin
      @@cacheidx, @channels = Marshal.load(io)
    rescue
      @channels = Marshal.load(io)
      @@cacheidx = 0
    end
  end

  # Save the cache to an IO stream
  def save(io)
    Marshal.dump([@@cacheidx, @channels], io)
  end
  
  # Return the number of channels in the cache
  def nbchannels
    @channels.length
  end

  # Return the number of items in the cache
  def nbitems
    nb = 0
    @channels.each_value { |c|
      nb += c.nbitems
    }
    nb
  end

  def ItemCache.getindex
    i = @@cacheidx
    @@cacheidx += 1
    i
  end
end

class CachedChannel
  attr_accessor :lastcheck, :items

  def initialize
    @lastcheck = Time::at(0)
    @items = []
  end

  # Returns the really new items amongst items
  def get_new_items(items)
    # set items' cached version if not set yet
    newitems = []
    updateditems = []
    items.each { |i| i.cacheditem ||= CachedItem::new(i) }
    items.each do |i|
      found = false
      # Try to find a perfect match
      @items.each do |j|
        if i.cacheditem == j
          i.cacheditem.index = j.index
          found = true
          break
        end
      end
      next if found
      # Try to find an updated item
      @items.each do |j|
        if i.link and i.link == j.link
          # Do we need a better heuristic ?
          i.cacheditem.index = j.index
          i.cacheditem.updated = true
          updateditems.push(i)
          found = true
          break
        end
      end
      next if found
      # add as new
      i.cacheditem.create_index
      newitems.push(i)
    end
    return [newitems, updateditems]
  end

  # Replace the existing cached items by those ones
  def update(items)
    @items = []
    items.each do |i|
      @items.push(i.cacheditem)
    end
    self
  end

  # returns the number of items
  def nbitems
    @items.length
  end
end

# This class is the only thing kept in the cache
class CachedItem
  attr_reader :title, :link, :hash
  attr_accessor :index
  attr_accessor :updated

  def initialize(item)
    @title = item.title
    @link = item.link
    if item.content.nil?
      @hash = nil
    else
      @hash = Digest::MD5.hexdigest(item.content.to_s)
    end
  end

  def ==(other)
    @title == other.title and @link == other.link and @hash == other.hash
  end

  def create_index
    @index = ItemCache.getindex
  end
end
