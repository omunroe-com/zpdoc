#!/usr/bin/ruby
# Program to replace commonly used html, extract out top and bottom parts
# of pages, which are roughly similar, and recompose them in the other end
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

require 'htmlshrinker-data'

class HTMLExpander
  def initialize(template, archive, basedir)   
    file = [%w(skins/common/wikibits.js skins/htmldump/md5.js skins/htmldump/utf8.js skins/htmldump/lookup.js raw/gen.js) , %w(raw/MediaWiki~Common.css raw/MediaWiki~Monobook.css raw/gen.css skins/htmldump/main.css skins/monobook/main.css)]
    # jscss = ['', '']
    # pretext = ['<style type="text/css">', '<script type="text/javascript">']
    # posttext = ['style', 'script']
    # 
    # (0..1).each do |no|
    #   file[no].each do |f|
    #     txt = archive.get_article(File.join(basedir, f))
    #     puts File.join(basedir,f), txt.size
    #     jscss[no] << pretext[no] << txt << posttext[no] unless txt.nil?  
    #   end
    # end
    # @jstext, @csstext = *jscss
    # @jstext.gsub!(/var ScriptSuffix(.*?)$/,'')   # includes <script> tag - messes up
    # @jstext = @jstext.gsub(/\/\*(.*?)\*\//m, '').gsub(/\/\/(.*?)$/, '') # rm comments
    # @csstext.gsub!(/\/\*(.*?)\*\//m, '')
    # @csstext.gsub!('@import "../monobook/main.css";', '') # we already included this
    @before, @after = template.split(20.chr)
    @before.sub!(/\<title>(.*?)\<\/title>/,'<title>TITLE</title>')
    @before.sub!(/\<h1 class\=\"firstHeading\">(.*?)\<\/h1>/, '<h1 class="firstHeading">TITLE</h1>')
#    @before = @before.gsub("raw", "/raw").gsub("./", "/")
#    @before.gsub!(HTMLShrinker_data::To_be_replaced, @jstext + @csstext)
  end

  def uncompress(text)
    title, text = text.split("\n", 2)
    HTMLShrinker_data::Replacements.each {|x, y| text.gsub!(y, x)}
    #gsub(/TITLE/, title).gsub("POINTER", @csstext + @jstext)
    return @before.gsub('TITLE', title) + text + @after
  end
end

class HTMLShrinker             
  def compress(text)
    if text =~ /\<meta http-equiv=\"Refresh\" content=\"0\;url=(.*?)\" \/\>/
      return "#R #{Regexp::last_match[1].gsub('../', '')}"
    end
    title = (text.match(/"firstHeading">(.*?)\<\/h1>/m) ? Regexp::last_match[1] : "Unnamed")
    text = Regexp::last_match[1] if text.match(/ start content -->(.*?)\<\!-- end content /m)   
    HTMLShrinker_data::Replacements.each {|x, y| text.gsub!(x, y) }
    ZUtil::strip_whitespace(text)
    text.gsub!(/<img src=(.*?)>/, "")
    return [title, text].join("\n")
  end
  
  # takes an example html file, extracts the top and bottom, does some replacements
  # - this can later be stored and handed to HTMLShrinker at initialization
  def extract_template(text)
    before = Regexp::last_match.pre_match if text.match(/<\!-- start content -->/)
    after = Regexp::last_match.post_match if text.match(/<\!-- end content -->/)       
    return [before, after].join(20.chr)
  end
end

