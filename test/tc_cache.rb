#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/cache'
require 'feed2imap/channel'
require 'pp'

class ItemCacheTest < Test::Unit::TestCase
  def test_create
    cache = ItemCache::new
    assert(! cache.nil?)
  end

  def test_cache_lastcheck
    cache = ItemCache::new
    assert_equal(Time::at(0), cache.get_last_check('coucou'))
    t = Time::now
    cache.set_last_check('coucou', t)
    assert_equal(t, cache.get_last_check('coucou'))
  end

  def test_cache_management
    c = ItemCache::new
    assert_equal(0, c.nbchannels)
    assert_equal(0, c.nbitems)
    i1 = Item::new
    i1.title = 'title1'
    i1.link = 'link1'
    i1.content = 'content1'
    i2 = Item::new
    i2.title = 'title2'
    i2.link = 'link2'
    i2.content = 'content2'
    assert_equal([i1, i2], c.get_new_items('id', [i1, i2])[0])
    c.update_cache('id', [i1])
    assert_equal(1, c.nbitems)
    assert_equal([i2], c.get_new_items('id', [i1, i2])[0])
  end

  def test_cache_management_updated
    c = ItemCache::new
    assert_equal(0, c.nbchannels)
    assert_equal(0, c.nbitems)
    i1 = Item::new
    i1.title = 'title1'
    i1.link = 'link1'
    i1.content = 'content1'
    i2 = Item::new
    i2.title = 'title2'
    i2.link = 'link2'
    i2.content = 'content2'
    news = c.get_new_items('id', [i1, i2])[0]
    assert_equal([i1, i2], news)
    idx1 = i1.cacheditem.index
    assert_equal(0, idx1)
    idx2 = i2.cacheditem.index
    assert_equal(1, idx2)
    c.update_cache('id', [i1, i2])
    i3 = Item::new
    i3.title = 'title 1 - updated'
    i3.link = 'link1'
    i3.content = 'content1'
    news, updated = c.get_new_items('id', [i3])
    assert_equal([], news)
    assert_equal([i3], updated)
    assert_equal(idx1, i3.cacheditem.index)
    i4 = Item::new
    i4.title = 'title 1 - updated'
    i4.link = 'link1'
    i4.content = 'content1 - modified'
    news, updated = c.get_new_items('id', [i4])
    assert_equal([], news)
    assert_equal([i4], updated)
    assert_equal(idx1, i4.cacheditem.index)
  end
end
