#!/usr/bin/ruby
# Program to replace commonly used html, extract out top and bottom parts
# of pages, which are roughly similar, and recompose them in the other end
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

require 'htmlshrinker-data'
require 'zutil'

class HTMLExpander
  attr_accessor :before, :after
  def initialize(template, replacements, iwnames, lang)
    @lang = lang         
    @iwnames = iwnames
    @replacements = replacements
    @before, @after = template.split(2.chr)
    @before.sub!(/\<title>(.*?)\<\/title>/,'<title>TITLE</title>')
    @before.gsub!('./', "/#{@lang}/")
    @after.gsub!(/href="([^\/])/, 'href="/' + @lang + '/\1')
#    @before.gsub!(/href="[^.]/, 'href="/\1')
    @before.sub!(/\<h1 class\=\"firstHeading\">(.*?)\<\/h1>/, '<h1 class="firstHeading">TITLE</h1>')  
    @after.sub!(/\<li id="f-credits">(.*?)\<\/li>/, '')
    @after.sub!(/(<div id="p-lang" class="portlet">)(.*?)(\<\/div>)/m, '\1IWLINKS\3')
  end

  def uncompress(text)
    title, languages, text = text.split(0.chr, 3)
    langs = languages.split(1.chr)
    result = extract_languages(langs)
    puts result
    @replacements.each {|x, y| text.gsub!(y, x)}
    return @before.gsub('TITLE', title) + text + @after.gsub("IWLINKS", result)
  end
end

  def extract_languages(langs)  
    result = '<h5>Interwiki</h5><div class="pBody"><ul>'
    (langs.size / 2).times do |no|
      id, link = langs[no * 2], langs[(no * 2) + 1]
      result << "<li><a href='/#{id}/#{link}'>#{@iwnames[id]}</a></li>"
    end                          
    return result + "</ul>"
  end

class HTMLShrinker   
  attr_accessor :replacements, :iwnames
  def initialize
    @iwnames = {}
    @replacements =  HTMLShrinker_data::Replacements
  end
  
  def compress(text)
    if text =~ /\<meta http-equiv=\"Refresh\" content=\"0\;url=(.*?)\" \/\>/
      url = url_unescape(Regexp::last_match[1].gsub('../', ''))
      return "#R #{url}"
    end
    title = (text.match(/"firstHeading">(.*?)\<\/h1>/m) ? Regexp::last_match[1] : "Unnamed")
    languages = ''
    if text.match(/<div id="p-lang" class="portlet">(.*?)\<\/div>/m)
      languages = Regexp::last_match[1]
      langs = {}
      languages.scan(/<a href="(.*?)">(.*?)\</) do |match|
        firstline = match[0].gsub("../", "")
        lang, url = firstline.split("/",2)
        langs[lang] = url
        @iwnames[lang] = match[1]
      end
      languages = langs.to_a.join(1.chr) 
    end
    text = Regexp::last_match[1] if text.match(/ start content -->(.*?)\<\!-- end content /m)   
    @replacements.each {|x, y| text.gsub!(x, y) }
    ZUtil::strip_whitespace(text)
#    text.gsub!(/\<!--(.*?)-->/, '')
    text.gsub!(/<img src=(.*?)>/, "")
    return [title, languages, text].join(0.chr)
  end
  
  # takes an example html file, extracts the top and bottom, does some replacements
  # - this can later be stored and handed to HTMLShrinker at initialization
  def extract_template(text)
    before = Regexp::last_match.pre_match if text.match(/<\!-- start content -->/)
    after = Regexp::last_match.post_match if text.match(/<\!-- end content -->/)       
    return [before, after].join(2.chr)
  end
end

