#!/usr/bin/ruby
%w(cgi rubygems mongrel zarchive htmlshrinker gui tk tk/root tk/frame tk/bindtag rubyscript2exe).each {|x| require x}

# from http://railsruby.blogspot.com/2006/07/url-escape-and-url-unescape.html
def url_escape(string)
  string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
    '%' + $1.unpack('H2' * $1.size).join('%').upcase
  end.tr(' ', '+')
end

def url_unescape(string)
  string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
    [$1.delete('%')].pack('H*')
  end
end                           
GUI.new
                       
dumpfile = File.join(RUBYSCRIPT2EXE.exedir, "..", 'Resources/archive')
extrafiles = File.join(RUBYSCRIPT2EXE.exedir, "..", 'Resources/extrafiles')
puts dumpfile
Archive = ZArchive.new(dumpfile)
Htmlshrink = HTMLShrinker.new(extrafiles)
Basename = ''
class SimpleHandler < Mongrel::HttpHandler
  def process(req, resp)
    t = Time.now                                    
    url = url_unescape(req.params['PATH_INFO'][1..-1])
    return if url =~ /(jpg|png|gif)$/
    url = url.gsub("%7E", "~")
    url = "#{Basename}/index.html" if url == "/"
    url = Basename + url unless url[0..(Basename.size-1)] == Basename 
    txt = Archive.get_article(url)
    if txt.nil?
      resp.write "Sorry, article not found" 
    else
      resp.write Htmlshrink.uncompress(txt)
    end
    puts "Served #{url} in #{Time.now - t} seconds."
  end
end 


H = Mongrel::HttpServer.new("0.0.0.0", "2042")
H.register("/", SimpleHandler.new)
H.register("/files", Mongrel::DirHandler.new("."))
trap("INT"){ H.stop; TkRoot.destroy; exit(0) } 
H.run

puts "Webserver started, serving at http://localhost:2042/"

Tk.mainloop
H.join
s_thread.join
