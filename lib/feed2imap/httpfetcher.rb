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
  require 'openssl'
rescue
end
require 'uri'

# Class used to retrieve the feed over HTTP
# TODO non standard port, authentification
# TODO don't use If-Mod-Since if = 0

if defined?(F2I_VERSION)
  USERAGENT = 'Feed2Imap v#{F2I_VERSION} http://home.gna.org/feed2imap/'
else
  USERAGENT = 'Feed2Imap http://home.gna.org/feed2imap/'
end

class HTTPFetcher
  def HTTPFetcher::fetcher(baseuri, uri, lastcheck, recursion)
    if uri.scheme == 'http'
      http = Net::HTTP::new(uri.host, uri.port)
    else
      http = Net::HTTPS::new(uri.host, uri.port)
    end
    req = Net::HTTP::Get::new(uri.request_uri, {'User-Agent' => USERAGENT, 'If-Modified-Since' => lastcheck.httpdate})
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
      raise "Timeout while fetching #{uri.to_s}"
    end
    case response
    when Net::HTTPSuccess
      return response.body
    when Net::HTTPRedirection
      # if not modified
      return nil if Net::HTTPNotModified === response
      if recursion > 0
        redir = URI::join(uri.to_s, response['location'])
        return fetcher(baseuri, redir, lastcheck, recursion - 1)
      end
    end
    # or raise en exception
    response.error!
  end
    
  def HTTPFetcher::fetch(url, lastcheck)
    uri = URI::parse(url)
    return HTTPFetcher::fetcher(uri, uri, lastcheck, 5)
    http = Net::HTTP::new(uri.host)
    response = http.get(uri.path, {'User-Agent' => USERAGENT, 'If-Modified-Since' => lastcheck.httpdate})
    if response.class == Net::HTTPOK
      return response.body
    elsif response.class == Net::HTTPNotModified
      return nil
    elsif response.class == Net::HTTPNotFound
      raise "Page not found (404)"
    else
      raise "Unknown response #{response.class}"
    end
  end
end
