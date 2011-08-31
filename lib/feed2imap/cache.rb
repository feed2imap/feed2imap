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

# debug mode
$updateddebug = false

# This class manages a cache of items
# (items which have already been seen)

require 'digest/md5'

class ItemCache
  def initialize(debug = false)
    @channels = {}
    @@cacheidx = 0
    $updateddebug = debug
    self
  end

  # Returns the really new items amongst items
  def get_new_items(id, items, always_new = false, ignore_hash = false)
    if $updateddebug
      puts "======================================================="
      puts "GET_NEW_ITEMS FOR #{id}... (#{Time::now})"
    end
    @channels[id] ||= CachedChannel::new
    @channels[id].parsefailures = 0
    return @channels[id].get_new_items(items, always_new, ignore_hash)
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
    @channels[id].failures = 0
    self
  end

  # Fetching failure.
  # returns number of failures
  def fetch_failed(id)
    @channels[id].fetch_failed
  end

  # Parsing failure.
  # returns number of failures
  def parse_failed(id)
    @channels[id].parse_failed
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
  # 100 items should be enough for everybody, even quite busy feeds
  CACHESIZE = 100

  attr_accessor :lastcheck, :items, :failures, :parsefailures

  def initialize
    @lastcheck = Time::at(0)
    @items = []
    @itemstemp = [] # see below
    @nbnewitems = 0
    @failures = 0
    @parsefailures = 0
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

  # Returns the really new items amongst items
  def get_new_items(items, always_new = false, ignore_hash = false)
    # save number of new items
    @nbnewitems = items.length
    # set items' cached version if not set yet
    newitems = []
    updateditems = []
    @itemstemp = @items
    items.each { |i| i.cacheditem ||= CachedItem::new(i) }
    if $updateddebug
      puts "-------Items downloaded before dups removal (#{items.length}) :----------"
      items.each { |i| puts "#{i.cacheditem.to_s}" }
    end
    # remove dups
    dups = true
    while dups
      dups = false
      for i in 0...items.length do
        for j in i+1...items.length do
          if items[i].cacheditem == items[j].cacheditem
            if $updateddebug
              puts "## Removed duplicate #{items[j].cacheditem.to_s}"
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
    if $updateddebug
      puts "-------Items downloaded after dups removal (#{items.length}) :----------"
      items.each { |i| puts "#{i.cacheditem.to_s}" }
      puts "-------Items already there (#{@items.length}) :----------"
      @items.each { |i| puts "#{i.to_s}" }
      puts "Items always considered as new: #{always_new.to_s}"
      puts "Items compared ignoring the hash: #{ignore_hash.to_s}"
    end
    items.each do |i|
      found = false
      # Try to find a perfect match
      @items.each do |j|
        # note that simple_compare only CachedItem, not RSSItem, so we have to use
        # j.simple_compare(i) and not i.simple_compare(j)
        if (i.cacheditem == j and not ignore_hash) or
            (j.simple_compare(i) and ignore_hash)
          i.cacheditem.index = j.index
          found = true
          # let's put j in front of itemstemp
          @itemstemp.delete(j)
          @itemstemp.unshift(j)
          break
        end
        # If we didn't find exact match, try to check if we have an update
        if j.is_ancestor_of(i)
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
      next if found
      # add as new
      i.cacheditem.create_index
      newitems.push(i)
      # add i.cacheditem to @itemstemp
      @itemstemp.unshift(i.cacheditem)
    end
    if $updateddebug
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
    if $updateddebug
      puts "Committing: new items: #{@nbnewitems} / items kept: #{@items.length}"
    end
    @itemstemp = []
    self
  end

  # returns the number of items
  def nbitems
    @items.length
  end

  def parse_failed
    @parsefailures = 0 if @parsefailures.nil?
    @parsefailures += 1
    return @parsefailures
  end

  def fetch_failed
    @failures = 0 if @failures.nil?
    @failures += 1
    return @failures
  end
end

# This class is the only thing kept in the cache
class CachedItem
  attr_reader :title, :link, :creator, :date, :hash
  attr_accessor :index
  attr_accessor :updated

  def initialize(item)
    @title = item.title
    @link = item.link
    @date = item.date
    @creator = item.creator
    if item.content.nil?
      @hash = nil
    else
      @hash = Digest::MD5.hexdigest(item.content.to_s)
    end
  end

  def ==(other)
    if $updateddebug
      puts "Comparing #{self.to_s} and #{other.to_s}:"
      puts "Title: #{@title == other.title}"
      puts "Link: #{@link == other.link}"
      puts "Creator: #{@creator == other.creator}"
      puts "Date: #{@date == other.date}"
      puts "Hash: #{@hash == other.hash}"
    end
    @title == other.title and @link == other.link and
        (@creator.nil? or other.creator.nil? or @creator == other.creator) and
	(@date.nil? or other.date.nil? or @date == other.date) and @hash == other.hash
  end

  def simple_compare(other)
    @title == other.title and @link == other.link and
        (@creator.nil? or other.creator.nil? or @creator == other.creator) 
  end

  def create_index
    @index = ItemCache.getindex
  end

  def is_ancestor_of(other)
    (@link and other.link and @link == other.link) and
      ((@creator and other.creator and @creator == other.creator) or (@creator.nil?))
  end

  def to_s
    "\"#{@title}\" #{@creator}/#{@date} #{@link} #{@hash}"
  end
end
