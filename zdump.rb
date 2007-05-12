#!/usr/bin/ruby
# Program that packs a directory tree into a zdump file.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage: ruby zdump.rb <directory> <output file> <template file>

%w(md5 zcompress find htmlshrinker zcompress zutil cgi).each {|x| require x}
include ZUtil                              
           
STDOUT.sync = true
class Index
  attr_reader :location, :redirects

  def initialize(file)
    @index = []   
    @file = file
    @entry = Struct.new(:filename, :block, :buflocation, :size, :md5)
    @cur_block, @buflocation, @size = *[0] * 4
    @buffer = ''
    @location = 4 # (to hold start of index)
    @block_ary = [] 
    @redirects= {}
  end

  def add(text, filename)
    # if redirect, add to index and keep going
    return @redirects[filename] = text[3..-1] if text[0..2] == "#R "
    entry = @entry.new(filename)    
    entry.buflocation = @buflocation
    entry.block = @cur_block                    
    entry.size = text.size
    entry.md5 = MD5::md5( entry.filename ).hexdigest
    firstfour = md5subset( entry.md5 )
    @index[firstfour] ||= []
    @index[firstfour] << entry
    @buffer << text
    @buflocation += text.size

    write_block if @buffer.size > 900000
  end

  def each_entry_with_index
    @index.each_with_index do |hash, idx|
      next if hash.nil?
      entry = ''  
      hash.each {|x| entry << pack(x.md5, @block_ary[x.block].start, @block_ary[x.block].size, x.buflocation, x.size) }
      yield entry, idx  
    end
  end                  

  def flush
    write_block unless @buffer.empty?     
    # deal with all the redirects 
    counter = 0
    @redirects.each do |file, target|
      counter += 1  
      puts "Processed #{counter} redirects." if counter / 40 == counter.to_f / 40.to_f
      target = target
      # in case of recursive redirects, which shouldn't happen, but alas
      recursion = 0
      while @redirects[target] && recursion < 3
        recursion += 1
         target = @redirects[url_unescape(target)]
       end
       md5 = MD5::md5( file ).hexdigest
       firstfour = md5subset( md5 )
       md5_target = MD5::md5( target ).hexdigest
       firstfour_target = md5subset( md5_target )
       entries = @index[firstfour_target]
       next if entries.nil?
       target = entries.select {|entry| entry.md5 == md5_target}
       
       # it really shouldn't be empty... if it is - the redirect is useless
       # anyway
       unless target.empty?         
         entry = target[0].dup  # so we don't overwrite the original
         entry.md5 = md5
         @index[firstfour] ||= []        
         @index[firstfour] << entry
       end
       
     end
  @redirects = nil   # clean up some memory
  end

  private
  def write_block
    bf_compr = ZCompress::compress(@buffer)
    writeloc(@file, bf_compr, @location)
    @block_ary[@cur_block] = Block.new(@cur_block, @location, bf_compr.size)
    @buffer = ''       
    @buflocation = 0
    @cur_block += 1                                           
    @location += bf_compr.size
    STDOUT.print "#{@cur_block} "
  end
end

if ARGV.size == 0  
  puts "Usage: ruby zdump.rb <directory> <output file> <template file>"
  exit(0)
end

shrinker = HTMLShrinker.new
Block = Struct.new(:number, :start, :size, :pages)                         

name = ARGV[1] 

t = Time.now
base = File.join(ARGV[0], "/")
puts "Indexing files in #{base} and writing the file #{name}"
to_strip = (base).size
zdump = File.open("#{name}", "w")
index = Index.new(zdump)        

ignore = ARGV[2] ? Regexp.new(ARGV[2]) : /(Berkas~|Pembicaraan|Templat|Pengguna)/ 

template = shrinker.extract_template(File.read(base + "index.html" ))
index.add template, "__Zdump_Template__"

no_of_files = 0       
all_counter = 0
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
STDOUT.print "Writing block: "
t2 = Time.now  
filelist.each_with_index do |newfile, counter|
  if (counter + 1).to_f / 1000.0 == (counter + 1) / 1000
    page_per_sec = counter.to_f / (Time.now - t2).to_f
    puts "\n#{counter} pages indexed in #{npp(Time.now - t)} seconds, average #{npp(page_per_sec)} files per second. #{index.redirects.size} redirects, #{npp(index.redirects.size.to_f * 100 / counter.to_f)} percentage of all pages."
    puts "Estimated time left: #{npp((no_of_files.to_f / page_per_sec) /60)} minutes."
    STDOUT.print "Writing block: "
  end             
  text = shrinker.compress(File.read(newfile))
  index.add(text, newfile[to_strip..-1])
end        
filelist = nil # memory cleanup

puts "\n\nFinished, flushing index/processing redirects. #{npp(Time.now - t)}"
index.flush # to make sure all blocks have been written

# writing start of index
location = index.location
writeloc(zdump, [location].pack('V'), 0)                      
puts "Size of archive without index #{location / 1024}kb."
puts "Writing index. #{npp(Time.now - t)} seconds."

indexloc = location
location = (65535*8) + indexloc

p = File.open(ARGV[1] + ".zlog","w")
index.each_entry_with_index do |entry, idx|
  next if entry.nil?  

  writeloc(zdump, [location, entry.size].pack('V2'), (idx * 8) + indexloc)
  writeloc(zdump, entry, location)

  p << "*" * 80 << "\n" 
  p << "seek #{(idx*8) + indexloc} location #{location} size #{entry.size}" << "\n"
  p << unpack(entry).join(":") << "\n"

  location += entry.size
end
puts "Finished in #{npp(Time.now - t)} seconds."
zdump.close
# p.close
