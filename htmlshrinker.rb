#!/usr/bin/ruby
# program to replace commonly used <HTML> to shrink size of page

require 'htmlshrinker-data'

class HTMLExpander
  def initialize(basedir, template)   
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

    @before, @after = template.split(20.chr)
  end

  def uncompress(text)
    title, text = text.split("\n", 2)
    HTMLShrinker_data::Replacements.each {|x, y| text.gsub!(y, x)}
    #.gsub(/TITLE/, title).gsub("POINTER", @csstext + @jstext)
    result = @before + text + @after
    return strip_whitespace(result)
  end
end

class HTMLShrinker             
  def compress(text)
    title = (text.match(/"firstHeading">(.*?)\<\/h1>/m) ? Regexp::last_match[1] : "Unnamed")
    text = Regexp::last_match[1] if text.match(/ start content -->(.*?)\<\!-- end content /m)   
    HTMLShrinker_data::Replacements.each {|x, y| text.gsub!(x, y) }
    strip_whitespace(text)
    text.gsub!(/<img src=(.*?)>/, "")
    return [title, text].join("\n")
  end
  
  # takes an example html file, extracts the top and bottom, does some replacements
  # - this can later be stored and handed to HTMLShrinker at initialization
  def create_template(text)
    before = Regexp::last_match.pre_match if text.match(/<\! -- start content -->/)
    after = Regexp::last_match.post_match if text.match(/<\!-- end content -->/)       
    return [before, after].join(20.chr)
  end
                                         
  private
  def strip_whitespace(txt)
    return txt.gsub(/\t/, " ").gsub('  ',' ').gsub("\n", '') 
  end
end