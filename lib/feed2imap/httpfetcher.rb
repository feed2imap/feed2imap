=begin
Feed2Imap - RSS/Atom Aggregator uploading to an IMAP Server
Copyright (c) 2005 Lucas Nussbaum <lucas@lucas-nussbaum.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
=end

require 'net/http'
# get openssl if available
begin
require 'net/https'
rescue LoadError
end
require 'uri'


# max number of redirections
MAXREDIR = 5

HTTPDEBUG = false

# Class used to retrieve the feed over HTTP
class HTTPFetcher
  def HTTPFetcher::fetcher(baseuri, uri, lastcheck, recursion)
    proxy_host = nil
    proxy_port = nil
    proxy_user = nil
    proxy_pass = nil
    if ENV['http_proxy']
        proxy_uri = URI.parse(ENV['http_proxy'])
        proxy_host = proxy_uri.host
        proxy_port = proxy_uri.port
        proxy_user, proxy_pass = proxy_uri.userinfo.split(/:/) if proxy_uri.userinfo
    end

    http = Net::HTTP::Proxy(proxy_host,
                            proxy_port,
                            proxy_user,
                            proxy_pass ).new(uri.host, uri.port)
    http.read_timeout = 30 # should be enough for everybody...
    http.open_timeout = 30
    if uri.scheme == 'https'
      http.use_ssl = true 
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    if defined?(Feed2Imap)
      useragent = "Feed2Imap v#{Feed2Imap.version} http://home.gna.org/feed2imap/"
    else
      useragent = 'Feed2Imap http://home.gna.org/feed2imap/'
    end

    if lastcheck == Time::at(0)
      req = Net::HTTP::Get::new(uri.request_uri, {'User-Agent' => useragent })
    else
      req = Net::HTTP::Get::new(uri.request_uri, {'User-Agent' => useragent, 'If-Modified-Since' => lastcheck.httpdate})
    end
    if uri.userinfo
      login, pw = uri.userinfo.split(':')
      req.basic_auth(login, pw)
    # workaround. eg. wikini redirects and loses auth info.
    elsif uri.host == baseuri.host and baseuri.userinfo
      login, pw = baseuri.userinfo.split(':')
      req.basic_auth(login, pw)
    end
    begin
      response = http.request(req)
    rescue Timeout::Error
      raise "Timeout while fetching #{baseuri.to_s}"
    end
    case response
    when Net::HTTPSuccess
      return response.body
    when Net::HTTPRedirection
      # if not modified
      if Net::HTTPNotModified === response
        puts "HTTPNotModified on #{uri}" if HTTPDEBUG
        return nil 
      end
      if recursion > 0
        redir = URI::join(uri.to_s, response['location'])
        return fetcher(baseuri, redir, lastcheck, recursion - 1)
      else
        raise "Too many redirections while fetching #{baseuri.to_s}"
      end
    else
      raise "#{response.code}: #{response.message} while fetching #{baseuri.to_s}"
    end
  end
    
  def HTTPFetcher::fetch(url, lastcheck)
    uri = URI::parse(url)
    return HTTPFetcher::fetcher(uri, uri, lastcheck, MAXREDIR)
  end
end
