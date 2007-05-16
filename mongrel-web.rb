#!/usr/bin/ruby
# Web server for viewing zdump files.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage:
# ruby mongrel-web.rb <zdumpfile> <path-prefix>

%w(cgi rubygems mongrel zarchive htmlshrinker).each {|x| require x}

Archive = ZArchive::Reader.new(ARGV[0])
template = Archive.get('__Zdump_Template__')
Htmlshrink = HTMLExpander.new(template, Archive)
Cache = {}
class SimpleHandler < Mongrel::HttpHandler
  def process(req, resp)
    resp.start(200) do |head, out|
      t = Time.now                                    
      url = ZUtil::url_unescape(req.params['PATH_INFO'][1..-1])
      url = "index.html" if url.empty?
      from_cache = false
    
      # if style/js
      if url =~ /(raw|skins|images)\/(.*?)$/
        url = Regexp::last_match[0]
        if Cache[url]
          text = Cache[url] 
          from_cache = true
        else
          text = Archive.get(url)
          return if text.nil? 
          line1, line2 = text.split("\n",2) 
          text = line2 if line1 == 'Unnamed'
          Cache[url] = text
        end
        out.write text
      else
        txt = Archive.get(url)
        txt ||= "Not found\n\nSorry, article #{url} not found" 
        out.write( Htmlshrink.uncompress(txt) )
      end
      head["Content-Type"] = case url
                                when /\.js$/: "text/javascript"               
                                when /\.css$/: "text/css"
                                when /\.html$/: "text/html"
                                end
      puts "Got #{url} #{from_cache ? 'from cache ' : ''}in #{"%2.3f" % (Time.now - t)} seconds."
    end
  end
end 
               
h = Mongrel::HttpServer.new("0.0.0.0", "2042")
h.register("/", SimpleHandler.new)

puts "Webserver started, serving at http://localhost:2042/"
h.run.join