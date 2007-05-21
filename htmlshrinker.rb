#!/usr/bin/ruby
# program to replace commonly used <HTML> to shrink size of page

require 'htmlshrinker-data'

class HTMLShrinker             
  def initialize(basedir)   
    js = %w(skins/common/wikibits.js skins/htmldump/md5.js skins/htmldump/utf8.js skins/htmldump/lookup.js raw/gen.js)
    css = %w(raw/MediaWiki~Common.css raw/MediaWiki~Monobook.css raw/gen.css skins/htmldump/main.css skins/monobook/main.css)
    @jstext, @csstext = '', ''
    cssbegin, cssend = '<style type="text/css">', '</style>' 
    jsbegin, jsend = '<script type="text/javascript">', '</script>'
    js.each {|f| @jstext << jsbegin << File.read(File.join(basedir, f)) << jsend if File.exists?(File.join(basedir, f)) }
    css.each {|f| @csstext << cssbegin << File.read(File.join(basedir, f)) << cssend if File.exists?(File.join(basedir, f)) }
    @jstext.gsub!(/var ScriptSuffix(.*?)$/,'')   # includes <script> tag - messes up
    @jstext = @jstext.gsub(/\/\*(.*?)\*\//m, '').gsub(/\/\/(.*?)$/, '') # rm comments
    @csstext.gsub!(/\/\*(.*?)\*\//m, '')
    @csstext.gsub!('@import "../monobook/main.css";', '') # we already included this
  end

  def compress(text)
    title = (text.match(/"firstHeading">(.*?)\<\/h1>/m) ? Regexp::last_match[1] : "Unnamed")
    text = Regexp::last_match[1] if text.match(/ start content -->(.*?)\<\!-- end content /m)   
    HTMLShrinker_data::Replacements.each {|x, y| text.gsub!(x, y) }
    strip_whitespace(text)
    text.gsub!(/<img src=(.*?)>/, "")
    return [title, text].join("\n")
  end

  def uncompress(text)
    title, text = text.split("\n", 2)
    HTMLShrinker_data::Replacements.each {|x, y| text.gsub!(y, x)}
    result = HTMLShrinker_data::Start.gsub(/TITLE/, title).gsub("POINTER", @csstext + @jstext) + text + HTMLShrinker_data::Ending
    return strip_whitespace(result)
  end
                                          
  def compress_file(filename)
    puts "Compressing #{filename}"
    text = File.read(filename)
    File.open(filename + ".shrunk", "w") {|f| f.write(compress(text)) } 
  end

  def uncompress_file(filename)
    puts "Uncompressing #{filename}"
    text = File.read(filename)
    File.open(filename[0..-(".shrunk".size+1)], "w") {|f| f.write(uncompress(text)) } 
  end

  def try(filename)
    puts "Creating #{filename}.try.html"
    text = File.read(filename)
    File.open(filename + ".try.html", "w") {|f| f.write(uncompress(compress(text))) } 
  end  

  private
  def strip_whitespace(txt)
    return txt.gsub(/\t/, " ").gsub('  ',' ').gsub("\n", '') 
  end
  
end

if __FILE__ == $0
  shrink = HTMLShrinker.new(File.join(File.dirname(ARGV[1]),"../../.."))
  p File.join(File.dirname(ARGV[1]),"../../..")           
 
  case ARGV.shift
    when 'compress'
      ARGV.each {|file| shrink.compress_file(file)}
    when 'uncompress'
      ARGV.each {|file| shrink.uncompress_file(file)}   
    when 'try'
      ARGV.each {|file| shrink.try(file)}
  end                    
end