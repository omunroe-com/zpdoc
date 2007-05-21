#!/usr/bin/ruby

# get a page displayed
homedir = File.dirname(__FILE__)
require File.join(homedir, 'zarchive')
archive = ZArchive.new(ARGV[0])
p archive.get_article(ARGV[1])