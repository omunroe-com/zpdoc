#!/usr/bin/ruby
# Program that packs a directory tree into a zdump file.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage: ruby zdump.rb <directory> <output file> <template file>

%w(sha1 rubygems zarchive find htmlshrinker zutil cgi trollop).each {|x| require x}
include ZUtil                              

STDOUT.sync = true

# do commandline parsing
opts = Trollop::options do
  version "zip-doc 0.1 (c) 2007 Stian Haklev (MIT/GPL)"
  banner <<-EOS
zdump.rb is part of the zip-doc suite. It basicallly processes the contents of a wikipedia-*-html.7z file (that has already been unextracted), and generates a .zdump file that can be used with mongrel-web.rb.

Usage:
       ruby zdump.rb [options] <path> <filename>
       (for example ruby zdump.rb ../Downloads/id)
where [options] are:
EOS

  opt :ignore, "Comma-separated list of file patterns to ignore, f. ex: ^User%talk,Discussion. ^ means begins at the start of a line, and % matches anything", :type => :string
  opt :idxsize, "Size of index, recommend 2 for small collections and 4 for Wikipedia", :type => :integer, :default => 4
  opt :zlib, "Use zlib instead of bzip2"
  opt :suffix, "No of letters to remove from path (default is usually good enough)", :type => :integer                     
  opt :blocksize, "Blocksize for compression in kb, defaults to 900", :type => :integer, :default => 900 
  opt :templatefile, "Name of template file (defaults to index.html in given directory)", :type => :string
end        

Trollop::die :idxsize, "out of range, must be between 1 and 7" unless !opts[:idxsize] || (opts[:idxsize] > 0 && opts[:idxsize] < 8)
Trollop::die :blocksize, "out of range, must be between 1 and 10000" unless !opts[:idxsize] || (opts[:idxsize] > 0 && opts[:idxsize] < 10001)
Trollop::die :templatefile, "does not exist" unless !opts[:templatefile] || File.exists?(opts[:templatefile])

# check the rest of the arguments
Trollop::die "Wrong number of arguments" unless ARGV.size == 2
dir = ARGV[0]
Trollop::die "Directory #{dir} does not exist or is not readable" unless File.exists?(dir)
Trollop::die "Directory #{ARGV[1]} does not exist" unless File.exists?(File.dirname(ARGV[1]))

# transform ignore to regexp
if opts[:ignore]
  ignore = Regexp.new(opts[:ignore].gsub('%', '.*?').split(',').join('|'))
end

shrinker = HTMLShrinker.new
name = ARGV[1] 

t = Time.now
base = File.join(dir, "/")
puts "Indexing files in #{base} and writing the file #{name}"
to_strip = opts[:suffix] ? opts[:suffix] : (base).size
compr = opts[:zlib] ? ZArchive::METHOD_ZLIB : ZArchive::METHOD_BZ2
archive = ZArchive::Writer.new(name, compr, opts[:idxsize], opts[:blocksize] * 1000)


template = shrinker.extract_template(File.read(base + "index.html" ))
archive.add("__Zdump_Template__", template)

no_of_files = 1       
all_counter = 1
puts "Reading filelist."
filelist = []
Find.find(base) do |newfile|                     
  all_counter += 1
  next if File.directory?(newfile) || !File.readable?(newfile)
  next if newfile =~ ignore
  filelist << newfile
  no_of_files += 1                  
end

puts "Filelist read, selected #{no_of_files} out of #{all_counter}, making up #{npp(100 * no_of_files.to_f / all_counter.to_f)}%."
puts "Beginning to compress."                 
t2 = Time.now  
filelist.each_with_index do |newfile, counter|
  if (counter).to_f / 1000.0 == (counter) / 1000
    page_per_sec = counter.to_f / (Time.now - t2).to_f
    puts "\n#{counter} pages indexed in #{npp(Time.now - t)} seconds, average #{npp(page_per_sec)} files per second. #{archive.hardlinks.size} redirects, #{npp(archive.hardlinks.size.to_f * 100 / counter.to_f)} percentage of all pages."
    puts "Estimated time left: #{npp(((no_of_files - counter).to_f / page_per_sec) /60)} minutes."
    STDOUT.print "Writing block: "
  end             
  text = shrinker.compress(File.read(newfile))
  if text[0..2] == "#R "
    archive.add_hardlink(newfile, text[3..-1])
  else
    archive.add(newfile[to_strip..-1], text)
  end
end        
filelist = nil # memory cleanup

puts "\n\nFinished, flushing index/processing redirects. #{npp(Time.now - t)}"
archive.flush # to make sure all blocks have been written
