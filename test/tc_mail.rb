#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/channel'
require 'rmail'

class ConfigTest < Test::Unit::TestCase
  def test_require_rmail
    # let's just test Rubymail is loaded
    m = RMail::Message::new
    assert_equal(m.class, RMail::Message)
  end
end
