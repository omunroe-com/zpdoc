#!/usr/bin/ruby
%w(md5 zcompress find htmlshrinker zcompress).each {|x| require x}
         
def unpack(string)
  return string.unpack('H32V4' * (string.size/32))
end  
  
def pack(md5, bstart, bsize, start, size)
  return [md5, bstart, bsize, start, size].pack('H32V4')
end

def md5subset(four)
  sprintf("%d", "0x" + four[0..3]).to_i                                                  
end
                 
class IO
  def writeloc(text, offset)
    self.seek offset
    self.write text
  end
end
                     
if ARGV.size == 0  
  puts "Usage: ruby zdump.rb <directory> <output file> <template file>"
  exit(0)
end
          
class Index
  def initialize
    @index = []
    @entry = Struct.new(:filename, :block, :buflocation, :size, :md5)
  end
     
  def add(*args)
     entry = @entry.new(*args)
     entry.md5 = Digest::MD5.hexdigest( entry.filename )
     firstfour = md5subset( entry.md5 )
     @index[firstfour] ||= []
     @index[firstfour] << entry
  end
                             
  def each_entry_with_index(block_ary)
    @index.each_with_index do |hash, idx|
      next if hash.nil?
      entry = ''  
      p hash
      hash.each {|x| entry << pack(x.md5, block_ary[x.block].start, block_ary[x.block].size, x.buflocation, x.size) }
      yield entry, idx  
    end
  end
end
      
      
          
shrinker = HTMLShrinker.new

Block = Struct.new(:number, :start, :size, :pages)                         
                                                   
index = Index.new         
block_ary = []
cur_block, counter, buflocation, size, buffer = 0, 0, 0, 0, ""
location = 4 # (to hold start of index)

name = ARGV[1] 
            
t = Time.now
puts "Indexing files in #{ARGV[0]}/ and writing the file #{name}"
zdump = File.open("#{name}", "w")
zdump.seek(location)

#ignore = ARGV[2] ? Regexp.new(ARGV[2]) : /^(Bilde~|Bruker|Pembicaraan_Pengguna~)/ 
ignore = /only ignore strange files/                  
template = shrinker.extract_template(File.read(ARGV[2]))
index.add "__Zdump_Template__", 0, 0, template.size
buffer << template
buflocation += template.size  

Find.find(ARGV[0]) do |newfile|
  next if File.directory?(newfile) || !File.readable?(newfile)
  next if newfile =~ ignore

  counter += 1                  
  if counter.to_i / 500.0 == counter / 500                                                             
    puts "#{counter} files indexed in #{Time.now - t}, average #{counter.to_f / (Time.now - t)} files per second. #{uncompr_size} data compressed to #{compr_size}, compression ratio #{compr_size.to_f / uncompr_size.to_f}." 
  end
  text = shrinker.compress(File.read(newfile))
  buffer << text

  md5 = Digest::MD5.hexdigest( newfile )
  firstfour = md5subset( md5 )
  index.add(newfile, cur_block, buflocation, text.size)

  buflocation += text.size
  
  next if buffer.size < 900000

  bf_compr = ZCompress::compress(buffer)
  zdump.write(bf_compr)
  block_ary[cur_block] = Block.new(cur_block, location, bf_compr.size)
  buffer = ''       
  buflocation = 0
  cur_block += 1                                           
  location += bf_compr.size
  puts "Writing block no #{cur_block}"
       
end        

# to ensure last part of buffer is written
bf_compr = ZCompress::compress(buffer)
zdump.write(bf_compr)
block_ary[cur_block] = Block.new(cur_block, location, bf_compr.size)
location += bf_compr.size                             

# writing start of index
zdump.writeloc([location].pack('V'), 0)                      
puts "location #{location}"
puts "Finished, writing index. #{Time.now - t}"
           
indexloc = location
location = (65535*8) + indexloc

p = File.open(ARGV[1] + ".zlog","w")
index.each_entry_with_index(block_ary) do |entry, idx|
  next if entry.nil?  

  zdump.writeloc([location, entry.size].pack('V2'), (idx * 8) + indexloc)
  zdump.writeloc(entry, location)

   p << "*" * 80 << "\n" 
   p << "seek #{(idx*8) + indexloc} location #{location} size #{entry.size}" << "\n"
   p << unpack(entry).join(":") << "\n"

  location += entry.size
end
puts "Finished. #{Time.now - t}"
zdump.close
# p.close