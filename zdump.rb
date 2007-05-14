#!/usr/bin/ruby
# Program that packs a directory tree into a zdump file.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage: ruby zdump.rb <directory> <output file> <template file>

%w(sha1 zarchive find htmlshrinker zutil cgi).each {|x| require x}
include ZUtil                              

STDOUT.sync = true

if ARGV.size == 0  
  puts "Usage: ruby zdump.rb <directory> <output file>"
  exit(0)
end

shrinker = HTMLShrinker.new
name = ARGV[1]   
template = ARGV[2] ? ARGV[2] : base + "index.html"

t = Time.now
base = File.join(ARGV[0], "/")
puts "Indexing files in #{base} and writing the file #{name}"
to_strip = (base).size
archive = ZArchive::Writer.new(name)

ignore = ARGV[2] ? Regexp.new(ARGV[2]) : /(Berkas~|Pembicaraan|Templat|Pengguna)/ 

template = shrinker.extract_template(File.read(template))
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
  end             
  text = shrinker.compress(File.read(newfile))
  filename = newfile[to_strip..-1]
  if text[0..2] == "#R "
    archive.add_hardlink(filename, text[3..-1])
  else
    archive.add(filename, text)
  end
end        
filelist = nil # memory cleanup
                      
archive.set_meta({:replacements => shrinker.replacements, :iwnames => shrinker.iwnames})
p shrinker.iwnames
puts "\n\nFinished, flushing index/processing redirects. #{npp(Time.now - t)}"
archive.flush # to make sure all blocks have been written
