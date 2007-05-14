#!/usr/bin/ruby
# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

# get a page displayed, used in debugging
require 'zarchive'        
require 'htmlshrinker'
archive = ZArchive::Reader.new(ARGV[0])
expander = HTMLExpander.new(archive.get('__Zdump_Template__'), archive.get_meta[:replacements])
p expander.uncompress(archive.get(ARGV[1]))
