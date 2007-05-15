#!/usr/bin/ruby
# Web server for viewing zdump files.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage:
# ruby mongrel-web.rb <zdumpfile> <path-prefix>

%w(cgi rubygems mongrel zarchive htmlshrinker wiki_reader).each {|x| require x}

unless File.exists?('.zipdoc-cache')
  Dir.mkdir('.zipdoc-cache')
end

lang = []
Dir.glob("*.zdump").each do |x| 
  lang << x.split(".")[0]
end
Lang = lang

class IndexHandler < Mongrel::HttpHandler
  def process(req, resp)
    resp.start(200) do |head, out|  
      Lang.each do |l|           
        filename = "wiki-#{l}.png" 
        File.open(File.join('.zipdoc-cache', filename), "w") do |f|
          f.write( ZArchive::Reader.new(l + ".zdump").get("images/#{filename}") )
        end
        out.write "<a href='/#{l}/index.html'><img src='/cache/wiki-#{l}.png'></a><br>" 
      end
    end
  end
end


class SimpleHandler < Mongrel::HttpHandler
  def initialize
    @@wikis = {}
  end

  def process(req, resp)
    resp.start(200) do |head, out|
      t = Time.now                                    
      url = ZUtil::url_unescape(req.params['PATH_INFO'][1..-1])
      url = "index.html" if url.empty?
      lang, url = url.split("/", 2)    
      puts "Lang #{lang} url #{url}"
      @@wikis[lang] = Wiki_reader.new(lang) unless @@wikis[lang]
      text = @@wikis[lang].get(url)
      from_cache = false
      head["Content-Type"] = case url
                            when /\.js$/: "text/javascript"               
                            when /\.css$/: "text/css"
                            when /\.html$/: "text/html"
                            end 
      out.write text

      puts "Got #{url} #{from_cache ? 'from cache ' : ''}in #{"%2.3f" % (Time.now - t)} seconds."
    end
  end
end 

h = Mongrel::HttpServer.new("0.0.0.0", "2042")
h.register("/", SimpleHandler.new)
h.register("/list", IndexHandler.new)
h.register("/cache", Mongrel::DirHandler.new(".zipdoc-cache"))

puts "Webserver started, serving at http://localhost:2042/"
h.run.join
