#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/textconverters'

class TextConvertersText2HTMLTest < Test::Unit::TestCase
  def test_detecthtml
    assert('<p>aaa</p>'.html?)
    assert('aaaaa<p>a<p>aa</p>'.html?)
    assert('aaaaa<br>aa'.html?)
    assert(!'aaaaa<bra>aa'.html?)
    assert('aaaaa<br/>aa'.html?)
    assert('aaaaa<br  /    >aa'.html?)
    assert(!'aaa bbb ccc > ddd'.html?)
  end

  def test_text2html
    output = "<p>Les brouillons pour la spécification OpenAL 1.1 sont en ligne....</p>
<p>L'annonce et le thread sur la mailing list :
<a href=\"http://opensource.creative.com/pipermail/openal-devel/2005-February(...)\">http://opensource.creative.com/pipermail/openal-devel/2005-February(...)</a></p>
<p>Ou télécharger (en pdf ou sxw )
<a href=\"http://openal.org/documentation.html(...)\">http://openal.org/documentation.html(...)</a>
</p>"
    input = <<-EOF
Les brouillons pour la spécification OpenAL 1.1 sont en ligne....

L'annonce et le thread sur la mailing list :
http://opensource.creative.com/pipermail/openal-devel/2005-February(...)

Ou télécharger (en pdf ou sxw )
http://openal.org/documentation.html(...)
    EOF
    assert_equal(output, input.text2html)
  end
end
