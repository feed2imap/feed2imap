#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/textconverters'

class TextConvertersHTML2TextTest < Test::Unit::TestCase
  def test_basic1
    inputtext = <<-EOF
<p> Ceci est un test. <br> On verra bien ce que ça donne ...</p>
    EOF
    outputtext = "Ceci est un test.
On verra bien ce que ça donne ..."
    assert_equal(outputtext, inputtext.html2text)
  end

  def test_basic2
    inputtext = <<-EOF
<p class="coucou"> Ceci est un test. On verra bien ce que ça donne ...</p>
<p class="coucou"> Ceci est un test. On verra bien ce que ça donne ...</p>
    EOF
    outputtext = "Ceci est un test. On verra bien ce que ça donne ...\n\nCeci est un test. On verra bien ce que ça donne ..."
    assert_equal(outputtext, inputtext.html2text)
  end

  def test_multiline
    inputtext = <<-EOF
<p class="coucou"> Ceci 


est 


un 

test. On 
verra 
bien ce que ça 
donne 
...</p>
    EOF
    outputtext = "Ceci est un test. On verra bien ce que ça donne ..."
    assert_equal(outputtext, inputtext.html2text)
  end

  def test_bui
    inputtext = <<-EOF
Ceci est un <b>test</b>. On <u>verra</u> <i>bien</i> ce
    EOF
    outputtext = "Ceci est un *test*. On _verra_ /bien/ ce"
    assert_equal(outputtext, inputtext.html2text)
  end

  def test_extchar
    inputtext = <<-EOF
test de caractères étendus : éàèç ah ah
    EOF
    outputtext = "test de caract\350res \351tendus : \351\340\350\347 ah ah"
    assert_equal(outputtext, inputtext.html2text)
  end

  def test_pre
    inputtext = <<-EOF
<p>le texte qui suit sera entre pre</p>
<pre>a b c
    aaa   ddd   eee
    ddd ee dfsdf dfdf dfd f df
</pre>
    <br/><br/>
<p>fin du pre !</p>
    EOF
    outputtext = "le texte qui suit sera entre pre\n\na b c\naaa   ddd   eee\nddd ee dfsdf dfdf dfd f df\n\nfin du pre !"
    assert_equal(outputtext, inputtext.html2text)
  end

  def test_link
    inputtext = <<-EOF
<p>ceci est un <a href="http://slashdot.org" style="">lien</a>. Ceci est un <a href=http://linuxfr.org/>autre lien</a></p>
    EOF
    outputtext = "ceci est un lien[1]. Ceci est un autre lien[2]\n\n[1] http://slashdot.org\n[2] http://linuxfr.org/"
    assert_equal(outputtext, inputtext.html2text)
  end
end
