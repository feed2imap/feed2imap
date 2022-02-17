require 'test/unit'
require 'feed2imap'
require 'mocha/test_unit'


class ItemToMailTest < Test::Unit::TestCase

  def jpg
    # a 1x1 white pixel
    "\xFF\xD8\xFF\xE0\u0000\u0010JFIF\u0000\u0001\u0001\u0000\u0000\u0001\u0000\u0001\u0000\u0000\xFF\xDB\u0000C\u0000\u0003\u0002\u0002\u0002\u0002\u0002\u0003\u0002\u0002\u0002\u0003\u0003\u0003\u0003\u0004\u0006\u0004\u0004\u0004\u0004\u0004\b\u0006\u0006\u0005\u0006\t\b\n\n\t\b\t\t\n\f\u000F\f\n\v\u000E\v\t\t\r\u0011\r\u000E\u000F\u0010\u0010\u0011\u0010\n\f\u0012\u0013\u0012\u0010\u0013\u000F\u0010\u0010\u0010\xFF\xC0\u0000\v\b\u0000\u0001\u0000\u0001\u0001\u0001\u0011\u0000\xFF\xC4\u0000\u0014\u0000\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\t\xFF\xC4\u0000\u0014\u0010\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\xFF\xDA\u0000\b\u0001\u0001\u0000\u0000?\u0000T\xDF\xFF\xD9"
  end

  def jpeg_base64
    # base64 encoding of the image in #jpg above
    "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQE\nBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/\nwAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAA\nAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==\n"
  end

  def config
    F2IConfig.new(StringIO.new("{}"))
  end

  def new_item
    feed = FeedParser::Feed.new
    feed.instance_variable_set("@title", "Some blog")
    feed.instance_variable_set("@link", "http://www.example.com/")
    item = FeedParser::FeedItem.new
    item.instance_variable_set("@feed", feed)
    item.title = "Some post"
    item
  end

  def test_img
    id = "abcd1234"
    item = new_item
    item.content = '<img src="http://www.example.com/pixel.jpg"/>'
    HTTPFetcher.any_instance.expects(:fetch).with("http://www.example.com/pixel.jpg", anything).returns(jpg)
    mail = item_to_mail(config, item, id, true, "feed2imap", true, false)
    assert_match %r{<img src="data:image/jpg;base64,#{jpeg_base64}"/>}, mail.to_s
  end

end
