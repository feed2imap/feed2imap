#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/channel'

class ChannelParserTest < Test::Unit::TestCase
  # From http://my.netscape.com/publish/formats/rss-spec-0.91.html
  def test_parse_rss091_1
    ch = Channel::new <<-EOF
<?xml version="1.0"?>
<!DOCTYPE rss SYSTEM "http://my.netscape.com/publish/formats/rss-0.91.dtd">
<rss version="0.91">
  <channel>
    <language>en</language>
    <description>News and commentary from the cross-platform scripting community.</description>
    <link>http://www.scripting.com/</link>
    <title>Scripting News</title>
    <image>
      <link>http://www.scripting.com/</link>
      <title>Scripting News</title>
      <url>http://www.scripting.com/gifs/tinyScriptingNews.gif</url>
    </image>
  </channel>
</rss>
    EOF
    assert_equal('Scripting News', ch.title)
    assert_equal('http://www.scripting.com/', ch.link)
    assert_equal('News and commentary from the cross-platform scripting community.', ch.description)
    assert_equal([], ch.items)
  end

  def test_parse_rss091_complete
    ch = Channel::new <<-EOF
<?xml version="1.0"?>
<!DOCTYPE rss SYSTEM "http://my.netscape.com/publish/formats/rss-0.91.dtd">
<rss version="0.91">
<channel>
<copyright>Copyright 1997-1999 UserLand Software, Inc.</copyright>
<pubDate>Thu, 08 Jul 1999 07:00:00 GMT</pubDate>
<lastBuildDate>Thu, 08 Jul 1999 16:20:26 GMT</lastBuildDate>
<docs>http://my.userland.com/stories/storyReader$11</docs>
<description>News and commentary from the cross-platform scripting community.</description>
<link>http://www.scripting.com/</link>
<title>Scripting News</title>
<image>
  <link>http://www.scripting.com/</link>
  <title>Scripting News</title>
  <url>http://www.scripting.com/gifs/tinyScriptingNews.gif</url>
  <height>40</height>
  <width>78</width>
  <description>What is this used for?</description>
</image>
<managingEditor>dave@userland.com (Dave Winer)</managingEditor>
<webMaster>dave@userland.com (Dave Winer)</webMaster>
<language>en-us</language>
<skipHours>
  <hour>6</hour><hour>7</hour><hour>8</hour><hour>9</hour><hour>10</hour><hour>11</hour>
</skipHours>
<skipDays>
  <day>Sunday</day>
</skipDays>
<rating>(PICS-1.1 "http://www.rsac.org/ratingsv01.html" l gen true comment "RSACi North America Server" for "http://www.rsac.org" on "1996.04.16T08:15-0500" r (n 0 s 0 v 0 l 0))</rating>
<item>
  <title>stuff</title>
  <link>http://bar</link>
  <description>This is an article about some stuff</description>
</item>
<item>
  <title>second item's title</title>
  <link>http://link2</link>
  <description>aa bb cc
  dd ee ff</description>
</item>
<textinput>
  <title>Search Now!</title>
  <description>Enter your search &lt;terms&gt;</description>
  <name>find</name>
  <link>http://my.site.com/search.cgi</link>
  </textinput>
</channel>
</rss>
    EOF
    assert_equal('Scripting News', ch.title)
    assert_equal('http://www.scripting.com/', ch.link)
    assert_equal('News and commentary from the cross-platform scripting community.', ch.description)
    assert_equal(2, ch.items.length)
    assert_equal('http://bar', ch.items[0].link)
    assert_equal('<p>This is an article about some stuff</p>', ch.items[0].content)
    assert_equal('stuff', ch.items[0].title)
    assert_equal('http://link2', ch.items[1].link)
    assert_equal("<p>aa bb cc\n  dd ee ff</p>", ch.items[1].content)
    assert_equal('second item\'s title', ch.items[1].title)
  end
end
