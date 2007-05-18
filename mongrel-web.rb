#!/usr/bin/ruby
# Web server for viewing zdump files.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage:
# ruby mongrel-web.rb <zdumpfile> <path-prefix>

%w(cgi rubygems mongrel zarchive htmlshrinker webrick trollop).each {|x| require x}
include WEBrick
Archive = ZArchive::Reader.new(ARGV[0])
template = Archive.get('__Zdump_Template__')
Htmlshrink = HTMLExpander.new(template, Archive)
Cache = {}       

# do commandline parsing
opts = Trollop::options do
  version "mongrel-web 0.1 (c) 2007 Stian Haklev (MIT/GPL)"
  banner <<-EOS
mongrel-web.rb is part of the zip-doc suite. It serves the contents of a .zdump file dynamically to localhost, allowing you to browse a wikipedia offline.

Usage:
       ruby mongrel-web.rb [options] <filename.zdump>
       (for example ruby mongrel-web.rb ../Downloads/id.zdump)
where [options] are:
EOS

  opt :sizes, "Insert sizes after each link, and change font-size based on size of linked-to article (very slow)"
  opt :prefix, "Insert a given prefix before any url - should not be necessary with standard zdump files", :type => :string, :default => ''
end                                                    

Base = opts[:prefix]

class NilLog
  def <<; end               
  def info(*args); end
  def error(*args); end
  def warn(*args); end
  def debug(*args); end
  def debug?(*args); false; end
end

def do_sizes(file, arc)
  content = file.match(/\<div id="contentSub"\>(.*?)<div class="printfooter">/m)[1]
  ary = []
  content.scan(/a href="\.\.\/\.\.\/\.\.\/(.*?)"(.*?)>(.*?)<\/a>/) do |match|
    ary << match
  end
  ary.each do |match|
    size = arc.get_size(ZUtil::url_unescape(match[0])) / 1000
      fsize = '-1' if size < 15 
      fsize = '+1' if size > 50
    content.sub!("<a href=\"../../../#{match[0]}\"#{match[1]}>#{match[2]}</a>", "<a href='/#{match[0]}' #{match[1]}><font size=#{fsize}>#{match[2]} (#{size}k)</font></a>")
  end
  content = '<div id="contentSub">' + content + "<div class='printfooter'>"
  file.gsub!(/\<div id="contentSub"\>(.*?)<div class="printfooter">/m, content)
end

wiki_proc = lambda do |req, resp| 
  resp['Content-Type'] = "text/html"
  url = ZUtil::url_unescape(req.unparsed_uri[1..-1])
  t = Time.now                                    
  url = "index.html" if url.empty?
  from_cache = ''

  # if style/js
  if url =~ /(raw|skins|images)\/(.*?)$/
    url = Base + Regexp::last_match[0]
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
    txt = Htmlshrink.uncompress(txt)
    txt = do_sizes(txt, Archive) if opts[:sizes]
    resp.body = ( txt )

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
