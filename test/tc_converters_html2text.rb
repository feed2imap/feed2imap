#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/textconverters'

class TextConvertersHTML2TextTest < Test::Unit::TestCase
  def test_t1
    inputtext = <<-EOF
<p> Ceci est un test. <br> On verra <b>bien</b> ce que ça donne ...</p>
    EOF
    outputtext = "Ceci est un test.
On verra bien ce que ça donne ..."
    assert_equal(outputtext, inputtext.html2text)
  end

  def test_t2
    inputtext = <<-EOF
<p class="coucou"> Ceci est un test. On verra <b>bien</b> ce que ça donne ...</p>
<p class="coucou"> Ceci est un test. On verra <b>bien</b> ce que ça donne ...</p>
    EOF
    outputtext = "Ceci est un test. On verra bien ce que ça donne ...\n\nCeci est un test. On verra bien ce que ça donne ..."
    assert_equal(outputtext, inputtext.html2text)
  end
end
