#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/config'
require 'stringio'

CONF1 = <<EOF
cache: /home/lucas/.feed2imap_cachedatabase
feeds: 
  - name: feed1
    url: http://something
    target: imap://login:pasword@ezaezae/Feeds/A
  - name: feed2
    url: http://something2
    target: imap://login:pasword@ezaezae/Feeds/B
EOF
CONF2 = <<EOF
feeds: 
  - name: feed1
    url: http://something
    target: imap://login:pasword@ezaezae/Feeds/A
  - name: feed2
    url: http://something2
    target: imaps://login:pasword@ezaezae/Feeds/B
EOF
CONFFEED = <<EOF
feeds: 
  - name: feed1
    url: feed:http://something
    target: imap://login:pasword@ezaezae/Feeds/A
  - name: feed2
    url: http://something2
    target: imaps://login:pasword@ezaezae/Feeds/B
EOF

class ConfigTest < Test::Unit::TestCase
  def test_cache
    sio = StringIO::new CONF1
    conf = F2IConfig::new(sio)
    assert_equal('/home/lucas/.feed2imap_cachedatabase', conf.cache)
    # testing default value
    sio = StringIO::new CONF2
    conf = F2IConfig::new(sio)
    assert_equal(ENV['HOME'] + '/.feed2imap.cache', conf.cache)
  end

  def test_accounts
    sio = StringIO::new CONF1
    conf = F2IConfig::new(sio)
    assert_equal(1, conf.imap_accounts.length)
    sio = StringIO::new CONF2
    conf = F2IConfig::new(sio)
    assert_equal(2, conf.imap_accounts.length)
  end

  def test_feedurls
    sio = StringIO::new CONFFEED
    conf = F2IConfig::new(sio)
    assert_equal('http://something', conf.feeds[0].url)
    assert_equal('http://something2', conf.feeds[1].url)
  end
end
