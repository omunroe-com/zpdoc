#!/usr/bin/ruby
require 'rubygems'
require 'mongrel'
homedir = '/users/stian/source/zip-doc'
require File.join(homedir, 'zarchive')
require File.join(homedir, 'htmlshrinker')
                           
              
archive = ZArchive.new(ARGV[0])
htmlshrink = HTMLShrinker.new("/id")
class SimpleHandler < Mongrel::HttpHandler
  def process(req, resp)
     p req
    t = Time.now    
    puts req
    txt = archive.get_article(req.unparsed_uri[3..-1])
    if txt.nil?
      out.write = "Sorry, article not found" 
    else
      out.write = htmlshrink.uncompress(txt)
    end
    puts "Served in #{Time.now - t} seconds."
  end
end 

search_proc = lambda do |req, resp|
  t = Time.now
  resp['Content-Type'] = "text/html"
  search_query =req.unparsed_uri[("search".size+2)..-1]
  puts search_queryearch_query
  @found_documents=[]
  FERRET.search_each(search_query) do |docid, score| 
    @found_documents << {:path => FERRET.reader.get_document(docid)[:filename], 
    :score => score, :highlight => FERRET.highlight(search_query, 
    docid, :pre_tag => '<b>', :post_tag => '</b>',
    :field => :content)}
  end
  resp.body = ""
  unless @found_documents.empty?
    resp.body <<  "<h1>Search results for query <i>#{search_query}</i></h1>"
    @found_documents.each do |doc|
      resp.body << "<li><a href=/d/#{doc[:path]}>#{doc[:path]}</a><br>#{doc[:highlight]}<br><hr>"
    end
  else
    resp.body << "Sorry, no documents found"
  end
  puts "Served in #{Time.now - t} seconds."
end

h = Mongrel::HttpServer.new("0.0.0.0", "3000")
h.register("/", SimpleHandler.new)
h.register("/files", Mongrel::DirHandler.new("."))
h.run.join
