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
                     
if ARGV.size == 0  
  puts "Usage: ruby zdump.rb <directory> <output file> <template file>"
end
          
shrinker = HTMLShrinker.new

Webpage = Struct.new(:filename, :block, :buflocation, :size) 
Block = Struct.new(:number, :start, :size, :pages)                         
                                                   
index = []             
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
index << Webpage.new("__Zdump_Template__", 0, 0, template.size)
buffer << template
buflocation += template.size  

Find.find(ARGV[0]) do |newfile|
  next if File.directory?(newfile) || !File.readable?(newfile)
  next if newfile =~ ignore

  counter += 1                  
  puts "#{counter} files indexed." if counter.to_i / 100.0 == counter / 100
  text = shrinker.compress(File.read(newfile))
  buffer << text

  index << Webpage.new(newfile, cur_block, buflocation, text.size)

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
zdump.seek(0)          
zdump.write([location].pack('V'))                      
puts "location #{location}"
puts "Finished, writing index. #{Time.now - t}"
           
pages = {}
index.each do |file|
  pages[file.filename] = {:block_start => block_ary[file.block].start,
                          :block_size => block_ary[file.block].size,
                          :start => file.buflocation,
                          :size => file.size}         
end
subindex = []                        

puts "Sorted onetime. #{Time.now - t}"
pages.each_pair do |x, y| 
  md5 = MD5.md5(x).hexdigest
  entry = pack(md5, y[:block_start], y[:block_size], y[:start], y[:size])
  firstfour = md5subset(md5)

  subindex[firstfour] = "" if subindex[firstfour].nil?
  subindex[firstfour] << entry
  if x == '__Zdump_Template__'
    puts y
    p firstfour
    puts md5
  end
end

puts "Sorted another time. #{Time.now - t}"
indexloc = location
location = (65535*8) + indexloc

p = File.open(ARGV[1] + ".zlog","w")
subindex.each_with_index do |entry, idx|
  next if entry.nil?  
  zdump.seek((idx * 8) + indexloc)                   
  zdump.print([location, entry.size].pack('V2'))
  zdump.seek(location)
  zdump.print(entry)         

   p << "*" * 80 << "\n" 
   p << "seek #{(idx*8) + indexloc} location #{location} size #{entry.size}" << "\n"
   p << unpack(entry).join(":") << "\n"

  location += entry.size
end
puts "Finished. #{Time.now - t}"
zdump.close
# p.close