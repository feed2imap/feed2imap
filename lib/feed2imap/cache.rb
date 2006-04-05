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
  def get_new_items(id, items, always_new = false)
    @channels[id] ||= CachedChannel::new
    return @channels[id].get_new_items(items, always_new)
  end

  # Commit changes to the cache
  def commit_cache(id)
    @channels[id] ||= CachedChannel::new
    @channels[id].commit
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
  # Size of the cache for each feed
  CACHESIZE = 50

  attr_accessor :lastcheck, :items

  def initialize
    @lastcheck = Time::at(0)
    @items = []
    @itemstemp = [] # see below
    @nbnewitems = 0
  end

  # Let's explain @items and @itemstemp.
  # @items contains the CachedItems serialized to the disk cache.
  # The - quite complicated - get_new_items method fills in @itemstemp
  # but leaves @items unchanged.
  # Later, the commit() method replaces @items with @itemstemp and
  # empties @itemstemp. This way, if something wrong happens during the
  # upload to the IMAP server, items aren't lost.
  # @nbnewitems is set by get_new_items, and is used to limit the number
  # of (old) items serialized.

  UPDATEDDEBUG = false

  # Returns the really new items amongst items
  def get_new_items(items, always_new = false)
    # save number of new items
    @nbnewitems = items.length
    # set items' cached version if not set yet
    newitems = []
    updateditems = []
    @itemstemp = @items
    items.each { |i| i.cacheditem ||= CachedItem::new(i) }
    # remove dups
    dups = true
    while dups
      dups = false
      for i in 0...items.length do
        for j in i+1...items.length do
          if items[i].cacheditem == items[j].cacheditem
            if UPDATEDDEBUG
              puts "## Removed #{items[j].cacheditem.to_s}"
            end
            items.delete_at(j)
            dups = true
            break
          end
        end
        break if dups
      end
    end
    # debug : dump interesting info to stdout.
    if UPDATEDDEBUG
      puts "-------Items downloaded :----------"
      items.each { |i| puts "#{i.cacheditem.to_s}" }
      puts "-------Items already there :----------"
      @items.each { |i| puts "#{i.to_s}" }
      puts "Items always considered as new: #{always_new.to_s}"
    end
    items.each do |i|
      found = false
      # Try to find a perfect match
      @items.each do |j|
        if i.cacheditem == j
          i.cacheditem.index = j.index
          found = true
          # let's put j in front of itemstemp
          @itemstemp.delete(j)
          @itemstemp.unshift(j)
          break
        end
      end
      next if found
      if not always_new
        # Try to find an updated item
        @items.each do |j|
          # Do we need a better heuristic ?
          if i.link and i.link == j.link
            i.cacheditem.index = j.index
            i.cacheditem.updated = true
            updateditems.push(i)
            found = true
            # let's put j in front of itemstemp
            @itemstemp.delete(j)
            @itemstemp.unshift(i.cacheditem)
            break
          end
        end
      end
      next if found
      # add as new
      i.cacheditem.create_index
      newitems.push(i)
      # add i.cacheditem to @itemstemp
      @itemstemp.unshift(i.cacheditem)
    end
    if UPDATEDDEBUG
      puts "-------New items :----------"
      newitems.each { |i| puts "#{i.cacheditem.to_s}" }
      puts "-------Updated items :----------"
      updateditems.each { |i| puts "#{i.cacheditem.to_s}" }
    end
    return [newitems, updateditems]
  end
  
  def commit
    # too old items must be dropped
    n = @nbnewitems > CACHESIZE ? @nbnewitems : CACHESIZE
    @items = @itemstemp[0..n]
    @itemstemp = []
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

  def to_s
    "\"#{@title}\" #{@link} #{@hash}"
  end
end
