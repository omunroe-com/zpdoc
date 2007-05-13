#!/usr/bin/ruby
# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

# get a page displayed, used in debugging
require 'zarchive'
archive = ZArchive::Reader.new(ARGV[0])
p archive.get(ARGV[1])
