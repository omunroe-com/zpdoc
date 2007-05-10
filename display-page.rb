#!/usr/bin/ruby
# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

# get a page displayed, used in debugging
homedir = File.dirname(__FILE__)
require File.join(homedir, 'zarchive')
archive = ZArchive.new(ARGV[0])
p archive.get_article(ARGV[1])