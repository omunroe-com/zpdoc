#!/usr/bin/ruby
# Program that packs a directory tree into a zdump file.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage: ruby zdump.rb <directory> <output file> <template file>

%w(md5 zcompress find htmlshrinker zcompress zutil).each {|x| require x}
include ZUtil                              

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
    firstfour = ZUtil::md5subset( entry.md5 )
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
      hash.each {|x| entry << ZUtil::pack(x.md5, @block_ary[x.block].start, @block_ary[x.block].size, x.buflocation, x.size) }
      yield entry, idx  
    end
  end                  

  def flush
    write_block unless @buffer.empty?     
    
    # deal with all the redirects
    @redirects.each do |file, target|
      
      # in case of recursive redirects, which shouldn't happen, but alas
      while @redirects[target]
        target = @redirects[target]
      end
      
      md5 = MD5::md5( file ).hexdigest
      firstfour = ZUtil::md5subset( md5 )
      md5_target = MD5::md5( target ).hexdigest
      firstfour_target = ZUtil::md5subset( md5_target )
      entries = @index[firstfour_target]
      target = entries.select {|entry| entry.md5 == md5_target}
      
      # it really shouldn't be empty... if it is - the redirect is useless
      # anyway
      unless target.empty?
        entry = target[0].dup  # so we don't overwrite the original
        entry.md5 = md5
        @index[firstfour] << entry
      end
    end
  end

  private
  def write_block
    bf_compr = ZCompress::compress(@buffer)
    ZUtil::writeloc(@file, bf_compr, @location)
    @block_ary[@cur_block] = Block.new(@cur_block, @location, bf_compr.size)
    @buffer = ''       
    @buflocation = 0
    @cur_block += 1                                           
    @location += bf_compr.size
    puts "Writing block no #{@cur_block}"
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

template = shrinker.extract_template(base + "index.html" )
index.add template, "__Zdump_Template__"

counter = 0
Find.find(base) do |newfile|
  next if File.directory?(newfile) || !File.readable?(newfile)
  next if newfile =~ ignore

  counter += 1                  
  if counter.to_i / 500.0 == counter / 500                                                             
    puts "#{counter} files indexed in #{"%.2f" % (Time.now - t)}, average #{"%.2f" % (counter.to_f / (Time.now - t).to_f)} files per second. #{index.redirects.size} redirects, #{"%.2f" % (index.redirects.size.to_f * 100 / counter.to_f)} percentage of all pages." 
  end             

  text = shrinker.compress(File.read(newfile))
  index.add(text, newfile[to_strip..-1])
end        

index.flush # to make sure all blocks have been written

# writing start of index
location = index.location
ZUtil::writeloc(zdump, [location].pack('V'), 0)                      
puts "Size of archive without index #{location}."
puts "Finished, writing index. #{Time.now - t}"

indexloc = location
location = (65535*8) + indexloc

# p = File.open(ARGV[1] + ".zlog","w")
index.each_entry_with_index do |entry, idx|
  next if entry.nil?  

  ZUtil::writeloc(zdump, [location, entry.size].pack('V2'), (idx * 8) + indexloc)
  ZUtil::writeloc(zdump, entry, location)

  # p << "*" * 80 << "\n" 
  # p << "seek #{(idx*8) + indexloc} location #{location} size #{entry.size}" << "\n"
  # p << unpack(entry).join(":") << "\n"

  location += entry.size
end
puts "Finished. #{Time.now - t}"
zdump.close
# p.close
