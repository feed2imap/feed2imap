#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/channel'

class ParserTest < Test::Unit::TestCase
  DATADIR = 'test/parserdata'
  def test_parser
    return if not File::exist?(DATADIR)
    allok = true
    Dir.foreach(DATADIR) do |f|
      next if f !~ /.xml$/
      str = File::read(DATADIR + '/' + f)
      chan = Channel::new(str)
      # for easier reading, go to ISO
      chanstr = chan.to_s
      chanstr = chanstr.unpack('U*').pack('C*')
      if File::exist?(DATADIR + '/' + f.gsub(/.xml$/, '.output'))
        output = File::read(DATADIR + '/' + f.gsub(/.xml$/, '.output'))
        File::open(DATADIR + '/' + f.gsub(/.xml$/, '.output.new'), "w") do |fd|
          fd.print(chanstr)
        end
        if output != chanstr
          puts "Test failed for #{f}. Try diff -u #{DATADIR + '/' + f.gsub(/.xml$/, '.output')}{,.new}"
          allok = false
        end
      else
        puts "Missing #{DATADIR + '/' + f.gsub(/.xml$/, '.output')}."
        File::open(DATADIR + '/' + f.gsub(/.xml$/, '.output.new'), "w") do |f|
          f.print(chanstr)
        end
      end
    end
    assert(allok)
  end
end
