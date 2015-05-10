#!/usr/bin/ruby

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/httpfetcher'

class HttpFetcherTest < Test::Unit::TestCase
  def test_get_https
    s = ''
    assert_nothing_raised do
      s = fetcher.fetch('https://linuxfr.org/pub/', Time::at(0))
    end
    assert(s.length > 20)
  end

  def test_get_http
  
  end

  def test_get_httpnotmodif
    s = 'aaa'
    assert_nothing_raised do
      s = fetcher.fetch('http://www.lucas-nussbaum.net/feed2imap_tests/notmodified.php', Time::new())
    end
    assert_nil(s)
  end

  def test_get_redir1
    s = 'aaa'
    assert_nothing_raised do
      s = fetcher.fetch("http://www.lucas-nussbaum.net/feed2imap_tests/redir.php?redir=#{MAXREDIR}", Time::at(0))
    end
    assert_equal('OK', s)
  end

  def test_get_redir2
    s = ''
    assert_raise(RuntimeError) do
      s = fetcher.fetch("http://www.lucas-nussbaum.net/feed2imap_tests/redir.php?redir=#{MAXREDIR + 1}", Time::at(0))
    end
  end

  def test_httpauth
    s = ''
    assert_nothing_raised do
      s = fetcher.fetch("http://aaa:bbb@ensilinx1.imag.fr/~lucas/f2i_redirauth.php", Time::at(0))
    end
    assert_equal("Login: aaa / Password: bbb \n", s)
  end

  def test_redirauth
    s = ''
    assert_nothing_raised do
      s = fetcher.fetch("http://aaa:bbb@ensilinx1.imag.fr/~lucas/f2i_redirauth.php?redir=1", Time::at(0))
    end
    assert_equal("Login: aaa / Password: bbb \n", s)
  end

  def test_notfound
    s = ''
    assert_raises(RuntimeError) do
      s = fetcher.fetch("http://ensilinx1.imag.fr/~lucas/notfound.html", Time::at(0))
    end
  end

  private

  def fetcher
    HTTPFetcher.new
  end
end
