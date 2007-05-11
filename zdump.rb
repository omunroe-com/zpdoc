#!/usr/bin/ruby
# Program that packs a directory tree into a zdump file.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Usage: ruby zdump.rb <directory> <output file> <template file>

%w(md5 zcompress find htmlshrinker zcompress zutil).each {|x| require x}
include ZUtil                              

class Index
  attr_reader :location

  def initialize(file)
    @index = []   
    @file = file
    @entry = Struct.new(:filename, :block, :buflocation, :size, :md5)
    @cur_block, @buflocation, @size = *[0] * 4
    @buffer = ''
    @location = 4 # (to hold start of index)
    @block_ary = []
  end

  def add(text, *args)

    entry = @entry.new(*args)    
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
puts "Indexing files in #{ARGV[0]}/ and writing the file #{name}"
zdump = File.open("#{name}", "w")
index = Index.new(zdump)        

ignore = ARGV[3] ? Regexp.new(ARGV[2]) : /(Bild~|Benutzer)/ 

template = shrinker.extract_template(File.read(ARGV[2]))
index.add template, "__Zdump_Template__", 0, 0, template.size

counter = 0
Find.find(ARGV[0]) do |newfile|
  next if File.directory?(newfile) || !File.readable?(newfile)
  next if newfile =~ ignore

  counter += 1                  
  if counter.to_i / 500.0 == counter / 500                                                             
    puts "#{counter} files indexed in #{"%.2f" % (Time.now - t)}, average #{"%.2f" % (counter.to_f / (Time.now - t).to_f)} files per second." 
  end             

  text = shrinker.compress(File.read(newfile))
  index.add(text, newfile)
end        

index.flush # to make sure all blocks have been written

# writing start of index
location = index.location
writeloc(zdump, [location].pack('V'), 0)                      
puts "Size of archive without index #{location}."
puts "Finished, writing index. #{Time.now - t}"

indexloc = location
location = (65535*8) + indexloc

# p = File.open(ARGV[1] + ".zlog","w")
index.each_entry_with_index do |entry, idx|
  next if entry.nil?  

  writeloc(zdump, [location, entry.size].pack('V2'), (idx * 8) + indexloc)
  writeloc(zdump, entry, location)

  # p << "*" * 80 << "\n" 
  # p << "seek #{(idx*8) + indexloc} location #{location} size #{entry.size}" << "\n"
  # p << unpack(entry).join(":") << "\n"

  location += entry.size
end
puts "Finished. #{Time.now - t}"
zdump.close
# p.close
