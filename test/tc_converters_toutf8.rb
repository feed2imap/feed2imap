#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/textconverters'

class TextConvertersToUTF8Test < Test::Unit::TestCase
  def test_correctencoding
    # tests with inputenc = real input encoding
    assert_equal("coucou", "coucou".toUTF8("utf-8"))
    assert_equal("\303\251\303\250\303\240", "יטא".toUTF8("iso-8859-1"))
    assert_equal("\303\251\303\250\303\240", "יטא".toUTF8("iso-8859-15"))
    assert_equal("\303\251\303\250\303\240", "\303\251\303\250\303\240".toUTF8("utf-8"))
  end
  
  # here comes the fun stuff
  def test_wrongencoding
    # test with inputenc = iso-8859-1 but really utf-8 (should output the UTF-8)
    assert_equal("\303\251\303\250\303\240", "\303\251\303\250\303\240".toUTF8("iso-8859-1"))

    # ISO in caps
    assert_equal("\303\251\303\250\303\240", "יטא".toUTF8("ISO-8859-1"))

    # UTF-8 in caps
    assert_equal("\303\251\303\250\303\240", "\303\251\303\250\303\240".toUTF8("UTF-8"))

    # test with inputenc = utf-8 but really iso-8859-1 (should output the UTF-8)
    # assert_equal("\303\251\303\250\303\240", TextConverters.toUTF8("יטא", "utf-8"))
    # TODO seems it is not do-able
  end
end
