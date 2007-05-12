#!/usr/bin/ruby
# Program to replace commonly used html, extract out top and bottom parts
# of pages, which are roughly similar, and recompose them in the other end
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

require 'htmlshrinker-data'

class HTMLExpander
  def initialize(template, archive)   
    @before, @after = template.split(20.chr)
    @before.sub!(/\<title>(.*?)\<\/title>/,'<title>TITLE</title>')
    @before.sub!(/.\//, '')
    @before.sub!(/\<h1 class\=\"firstHeading\">(.*?)\<\/h1>/, '<h1 class="firstHeading">TITLE</h1>')  
    @after.sub!(/\<li id="f-credits">(.*?)\<\/li>/, '')
    
  end

  def uncompress(text)
    title, languages, text = text.split("\n", 3)
#    p languages.split(":")
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
    languages = ''
    # if text.match(/<div id="p-lang" class="portlet">(.*?)\<\/div>/)
    #   languages = Regexp::last_match[1]
    #   langs = {}
    #   languages.scan(/<a href="(.*?)">/) do |match|
    #     match = match[0].gsub("../", "")
    #     lang, url = match.split("/",2)
    #     langs[lang] = url
    #   end
    #   languages = langs.to_a.join(":") 
    #   p languages
    # end
    text = Regexp::last_match[1] if text.match(/ start content -->(.*?)\<\!-- end content /m)   
    HTMLShrinker_data::Replacements.each {|x, y| text.gsub!(x, y) }
    ZUtil::strip_whitespace(text)
    text.gsub!(/<img src=(.*?)>/, "")
    return [title, languages, text].join("\n")
  end
  
  # takes an example html file, extracts the top and bottom, does some replacements
  # - this can later be stored and handed to HTMLShrinker at initialization
  def extract_template(text)
    before = Regexp::last_match.pre_match if text.match(/<\!-- start content -->/)
    after = Regexp::last_match.post_match if text.match(/<\!-- end content -->/)       
    return [before, after].join(20.chr)
  end
end

