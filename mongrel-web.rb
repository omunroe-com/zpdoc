#!/usr/bin/ruby
# Web server for viewing zdump files.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage:
# ruby mongrel-web.rb <zdumpfile> <path-prefix>

%w(cgi rubygems mongrel zarchive htmlshrinker webrick).each {|x| require x}
include WEBrick
Archive = ZArchive::Reader.new(ARGV[0])
template = Archive.get('__Zdump_Template__')
Htmlshrink = HTMLExpander.new(template, Archive)
Cache = {}           
                                                 
class NilLog
  def <<
  end               
  def info(*args); end
  def warn(*args); end
  def debug(*args); end
  def debug?(*args); false; end
end

wiki_proc = lambda do |req, resp| 
  resp['Content-Type'] = "text/html"
  url = ZUtil::url_unescape(req.unparsed_uri[1..-1])
  t = Time.now                                    
  url = "index.html" if url.empty?
  from_cache = ''

  # if style/js
  if url =~ /(raw|skins|images)\/(.*?)$/
    url = Regexp::last_match[0]
    if Cache[url]
      text = Cache[url] 
      from_cache = 'from cache '
    else
      text = Archive.get(url)
      return if text.nil? 
      line1, line2 = text.split("\n",2) 
      text = line2 if line1 == 'Unnamed'
      Cache[url] = text
    end
    resp.body = text
  else
    txt = Archive.get(url)
    txt ||= "Not found\n\nSorry, article #{url} not found" 
    resp.body = ( Htmlshrink.uncompress(txt) )
  end
  resp["Content-Type"] = case url
  when /\.js$/: "text/javascript"               
  when /\.css$/: "text/css"
  when /\.html$/: "text/html"
  end
  puts "Got #{url} #{from_cache}in #{"%2.3f" % (Time.now - t)} seconds."
end

wiki = HTTPServlet::ProcHandler.new(wiki_proc) 
SERVER = HTTPServer.new(:Port => 2042, :DocumentRoot => Dir.pwd, :Logger => NilLog.new ) 

SERVER.mount("/", wiki) 
trap("INT"){ SERVER.shutdown;  exit(0) } 
puts "Server started, website accessible at http://localhost:2042."
SERVER.start
