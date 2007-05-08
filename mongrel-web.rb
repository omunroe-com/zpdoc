#!/usr/bin/ruby
%w(cgi rubygems mongrel zarchive htmlshrinker).each {|x| require x}

# from http://railsruby.blogspot.com/2006/07/url-escape-and-url-unescape.html
def url_unescape(string)
  string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
    [$1.delete('%')].pack('H*')
  end
end                           

Archive = ZArchive.new(ARGV[0])
Htmlshrink = HTMLShrinker.new(ARGV[1])
Basename = ARGV[2].nil? ? '' : ARGV[2]
class SimpleHandler < Mongrel::HttpHandler
  def process(req, resp)
    t = Time.now                                    
    url = url_unescape(req.params['PATH_INFO'][1..-1])
#    return if url =~ /(jpg|png|gif)$/
    url = "#{Basename}index.html" if url.empty?
    url = Basename + url unless url[0..(Basename.size-1)] == Basename 
    txt = Archive.get_article(url)
    resp.write txt.nil? ? "Sorry, article not found" : Htmlshrink.uncompress(txt)
    puts "Served #{url} in #{Time.now - t} seconds."
  end
end 


