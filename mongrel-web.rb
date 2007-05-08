#!/usr/bin/ruby
%w(cgi rubygems mongrel zarchive htmlshrinker).each {|x| require x}

# from http://railsruby.blogspot.com/2006/07/url-escape-and-url-unescape.html
def url_unescape(string)
  string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
    [$1.delete('%')].pack('H*')
  end
end                           

Archive = ZArchive.new(ARGV[0])
template = Archive.get_article('__Zdump_Template__')
Basename = ARGV[1].nil? ? '' : ARGV[1]
Htmlshrink = HTMLExpander.new(template, Archive, Basename)
class SimpleHandler < Mongrel::HttpHandler
  def process(req, resp)
    t = Time.now                                    
    url = url_unescape(req.params['PATH_INFO'][1..-1])
#    return if url =~ /(jpg|png|gif)$/
    url = "#{Basename}index.html" if url.empty?
    url = Basename + url unless url[0..(Basename.size-1)] == Basename 
    
    # if style/js
    if url.match(/(raw|skins|images)\/(.*?)$/)
      url = Basename + Regexp::last_match[0]
      resp.write Archive.get_article(url)
    else
      txt = Archive.get_article(url)
      resp.write txt.nil? ? "Sorry, article not found" : Htmlshrink.uncompress(txt)
      
    end
  end
end 


h = Mongrel::HttpServer.new("0.0.0.0", "2042")
h.register("/", SimpleHandler.new)
h.register("/raw", Mongrel::DirHandler.new("raw"))
h.register("/skins", Mongrel::DirHandler.new("skins"))

puts "Webserver started, serving at http://localhost:2042/"
h.run.join
