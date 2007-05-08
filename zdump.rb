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
                                                 
HTMLSHRINKER = HTMLShrinker.new(ARGV[1])

class Webpage    
  attr_reader :text, :compressed, :size, :compressed_size, :filename, :index_content, :block, :buflocation
  
  def initialize(filename, block, buflocation)
    @filename = filename                                                                    
    @block = block
    @text = HTMLSHRINKER.compress(File.read(filename))
    @size = @text.size
    @buflocation = buflocation
  end
                    
  def empty!
    @text = ''
    @index_content = ''
  end
end
            
Block = Struct.new(:number, :start, :size, :pages)                         
                                                   
index = []             
block_ary = []  
uncompr_size, compr_size, cur_block, counter, buflocation, size = *[0] * 6
buffer = ''
location = 4 # (to hold start of index)

name = (ARGV[1] ? ARGV[1] : "default")
            
t = Time.now
puts "Indexing files in #{ARGV[0]}/ and writing the file #{name}"
zdump = File.open("#{name}", "w")
zdump.seek(location)

ignore = ARGV[2] ? Regexp.new(ARGV[2]) : /^(Bilde~|Bruker|Pembicaraan_Pengguna~)/ 

Find.find(ARGV[0]) do |newfile|
  next if File.directory?(newfile) || !File.readable?(newfile)
  next if newfile =~ ignore

  counter += 1                  
  if counter.to_i / 1000.0 == counter / 1000                                                               
    puts "#{counter} files indexed in #{Time.now - t}, average #{counter.to_f / (Time.now - t)} files per second. #{uncompr_size} data compressed to #{compr_size}, compression ratio #{compr_size.to_f / uncompr_size.to_f}." 
  end

  wf = Webpage.new(newfile, cur_block, buflocation)
  buflocation += wf.text.size
  wf.empty!
  index << wf
  next if buffer.size < 900000    

  bf_compr = ZCompress.compress(buffer)
  compr_size += bf_compr.size
  zdump.write(bf_compr)
  block_ary[cur_block] = Block.new(cur_block, location, bf_compr.size)
  buffer = ''       
  uncompr_size += buflocation
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
           
subindex = []                        
index.each_pair do |file| 
  md5 = Digest::MD5.hexdigest( file.filename )
  firstfour = md5subset( md5 )
  entry = pack(md5, block_ary[file.block].start, block_ary[file.block].size, file.buflocation, file.size)
  subindex[firstfour] ||= "" 
  subindex[firstfour] << entry
end

puts "Sorted one time. #{Time.now - t}"        

indexloc = location
subidxloc = (65535*8) + indexloc    # 65535 = 0xFFFF

subindex.each_with_index do |entry, idx|
  next if entry.nil?  
  zdump.writeloc( [location, entry.size].pack('V2'), (idx * 8) + indexloc )                   
  zdump.writeloc(entry, subidxloc)
  subidxloc += entry.size
end

zdump.close
puts "Finished. #{Time.now - t}"