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
          
#ZFERRET = Ferret::Index::Index.new(:path => "#{ARGV[1]}.zferret")
HTMLSHRINKER = HTMLShrinker.new(ARGV[1])

# File lib/dipus/util.rb, line 229
class String
  def rsplit(*args, &block)
    reverse.split(*args, &block).reverse.map{|s| s.reverse }
  end
end


class Webpage    
  attr_reader :text, :compressed, :size, :compressed_size, :filename, :index_content, :block, :buflocation
  
  def initialize(filename, block, buflocation)
    @filename = filename                                                                    
    @block = block
    @text = HTMLSHRINKER.compress(File.read(filename))
    @size = @text.size
#    @index_content = index_content           
    @buflocation = buflocation
  end
                    
  def empty!
    @text = ''
    @index_content = ''
  end
  
  def index_content
    content = ""
    case @filename
      when /.txt$/i
        content = @text

      when /.htm$|.html$/i        # get the file, strip all <> tags
        content = @text.gsub(/\<head>.*?\<\/head>/im,"").gsub(/\<.*?\>/m, " ")
    end
    return content.strip
  end    
end
            
class Block                         
  attr_reader :number, :start, :size
  def initialize(number, start, size)  
    @number = number
    @start = start
    @size = size
  end
end
                                                   
index = []             
block_ary = []
cur_block, counter, buflocation, location, size, buffer = 0, 0, 0, 0, 0, ""
name = (ARGV[1] ? ARGV[1] : "default")
            
t = Time.now
puts "Indexing files in #{ARGV[0]}/ and writing the file #{name}.zindex and directory #{name}.zferret."
zdump = File.open("#{name}.zdump", "w")
ignore = ARGV[2] ? Regexp.new(ARGV[2]) : /^(Bilde~|Bruker|Pembicaraan_Pengguna~)/ 
filelist = []
`7za l #{ARGV[0]}`.each do |line| 
  a, b = line.rsplit(" ", 2)
  next if b.nil?
  filelist << b if b.match("/") && b.match(".")
end
p filelist
#Find.find(ARGV[0]) do |newfile|
filelist.each do |newfile|
  puts newfile                
  puts "7za x -y #{ARGV[0]} #{newfile}"
  `7za x #{ARGV[0]} #{newfile}`
#  next if File.directory?(newfile) || !File.readable?(newfile)
  next if newfile =~ ignore
  wf = Webpage.new(newfile, cur_block, buflocation)
  puts "#{counter} files indexed." if counter.to_i / 100.0 == counter / 100

  buffer << wf.text
  buflocation += wf.text.size
  wf.empty!
  counter += 1                  
  index << wf
  next if buffer.size < 900000

  bf_compr = ZCompress::compress(buffer)
  zdump.write(bf_compr)
  block_ary[cur_block] = Block.new(cur_block, location, bf_compr.size)
  buffer = ''       
  buflocation = 0
  cur_block += 1                                           
  location += bf_compr.size
  puts "Writing block no #{cur_block}"
       
#  ZFERRET << {:filename => wf.filename, :content => wf.index_content, :offset => location, :size => wf.compressed_size } 
#  location += wf.compressed_size
 
end        

# to ensure last part of buffer is written
bf_compr = ZCompress::compress(buffer)
zdump.write(bf_compr)
block_ary[cur_block] = Block.new(cur_block, location, bf_compr.size)
                             
zdump.close
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
end

puts "Sorted another time. #{Time.now - t}"

newindex = File.open(name +".zindex",'w+')
location = (65535*8)
# p = File.open(name + ".zlog",'w')
subindex.each_with_index do |entry, idx|
  next if entry.nil?  
  newindex.seek(idx*8)                   
  newindex.print([location, entry.size].pack('V2'))
  newindex.seek(location)
  newindex.print(entry)         

  # p << "*" * 80 << "\n" 
  # p << "seek #{idx*8} location #{location} size #{entry.size}" << "\n"
  # p << unpack(entry).join(":") << "\n"

  location += entry.size
end
puts "Finished. #{Time.now - t}"
newindex.close
# p.close