#!/usr/bin/ruby -w

# This script takes a lot of .xml files, parse them, and ensure that each of them has at least
# channel : a title, a link
# each item : a title, a link, a content

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'channel'

XMLDIR = '../opml/output/'
DETAILED = true
def do_dir(dir)
  Dir.foreach(dir) do |f|
    next if f !~ /.xml$/
    do_file(XMLDIR + f)
  end
end

def do_file(file)
  print "#{file} : "
  str = File::read(file)
  if str.length == 0
    puts "EMPTY"
    return
  end
  begin
    chan = Channel::new(str)
  rescue UnknownFeedTypeException
    puts "UNKNOWNFEEDTYPE"
    return
  rescue Exception
    puts "EXCEPTION"
    puts $!
    return
  end
  ok = true
  if chan.title.nil?
    ok = false
    puts "Channel Title Empty" if DETAILED
  end
  if chan.link.nil?
    ok = false
    puts "Channel Link Empty" if DETAILED
  end
  if chan.items.length == 0
    ok = false
    puts "Channel Items Empty" if DETAILED
  end
  chan.items.each do |i|
    if i.title.nil?
      ok = false
      puts "Item Title Empty" if DETAILED
    end
    if i.link.nil?
      ok = false
      puts "Item Link Empty" if DETAILED
    end
    if i.content.nil?
      ok = false
      puts "Item Content Empty" if DETAILED
    end
  end
  if ok
    puts "OK"
  else
    puts "ERROR"
  end
end

STDOUT.sync = true
#do_file('../opml/output/112.xml')
do_dir(XMLDIR)

