#!/usr/bin/ruby
# Program that packs a directory tree into a zdump file.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage: ruby zdump.rb <directory> <output file> <template file>

%w(sha1 zArchive find htmlShrinker zutil cgi).each {|x| require x}
include ZUtil                              

STDOUT.sync = true

if ARGV.size == 0  
  puts "Usage: ruby zdump.rb <directory> <output file>"
  exit(0)
end

Shrinker = HTMLShrinker.new
name = ARGV[1] 

t = Time.now
base = File.join(ARGV[0], "/")
puts "Indexing files in #{base} and writing the file #{name}"
To_strip = (base).size
Archive = ZArchive::Writer.new(name)

ignore = ARGV[2] ? Regexp.new(ARGV[2]) : /(Berkas~|Pembicaraan|Templat|Pengguna)/ 

template = Shrinker.extract_template(File.read(base + "index.html" ))
Archive.add("__Zdump_Template__", template)

no_of_files = 1       
all_counter = 1
puts "Reading filelist."
filelist = []
filelist[1] = []
filelist[2] = []
flist_no = 1
Find.find(base) do |newfile|                     
  all_counter += 1
  next if File.directory?(newfile) || !File.readable?(newfile)
  next if newfile =~ ignore
  filelist[flist_no] << newfile
  no_of_files += 1                  
  flist_no == 1 ? 2 : 1
end
No_of_files = no_of_files                                   
puts "Filelist read, selected #{no_of_files} out of #{all_counter}, making up #{npp(100 * no_of_files.to_f / all_counter.to_f)}%."
puts "Beginning to compress."                 
t2 = Time.now  

def do_filelist(list)
  counter = 0
  t2 = Time.now
  list.each_with_index do |newfile, counter|
    if (counter).to_f / 1000.0 == (counter) / 1000
      page_per_sec = counter.to_f / (Time.now - t2).to_f
      puts "\n#{counter} pages indexed in #{npp(Time.now - t2)} seconds, average #{npp(page_per_sec)} files per second. #{Archive.hardlinks.size} redirects, #{npp(Archive.hardlinks.size.to_f * 100 / counter.to_f)} percentage of all pages."
      puts "Estimated #{npp((No_of_files.to_f / page_per_sec) / 60)} minutes left."
      STDOUT.print "Writing block: "
    end             
    text = Shrinker.compress(File.read(newfile))
    if text[0..2] == "#R "
      Archive.add_hardlink(newfile, text[3..-1])
    else
      Archive.add(newfile[To_strip..-1], text)
    end
  end        
end

t1 = Thread.new {do_filelist(filelist[1])}
t2 = Thread.new {do_filelist(filelist[2])}

t1.join
t2.join
filelist = nil # memory cleanup

puts "\n\nFinished, flushing index/processing redirects. #{npp(Time.now - t)}"
Archive.flush # to make sure all blocks have been written
