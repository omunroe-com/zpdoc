# Library for storing and accessing arbitrary chunks of compressed data.
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
# 
# Usage example: 
# require 'zarchive'
# archive = ZArchive::Writer.new('eo.zdump')
# index = File.read('index.html')
# archive.add('index.html', index)
# archive.add_hardlink('index.htm', 'index.html)
# archive.flush
# 
# archive = ZArchive::Reader.new('eo.zdump')
# puts(archive.get('index.html))

%w(md5 zutil).each {|x| require x} 

module ZArchive
  class Compressor
    # methods are bz2 and zlib
    attr_reader :method

    def initialize(method)
      @method = method
      require 'bz2' if @method == :bz2
    end

    def uncompress(txt)
      case @method   
      when :bz2 : BZ2::Reader.new(txt).read
      when :zlib : Zlib::Inflate.new.inflate(txt)  
      end            
    end

    # compresses a textchunk, that is able to be uncompressed independently
    def compress(txt)
      case @method
      when :bz2 : (BZ2::Writer.new << txt).flush
      when :zlib : Zlib::Deflate.new.deflate(txt, Zlib::FINISH)      
      end
    end
  end

  class Reader               
    include ZUtil
    def initialize(file, method = :bz2)
      @file = file                    
      @compressor = Compressor.new(method)
    end

    def get(url)
      # we open this on each request, because otherwise it gets messy with threading
      zdump = File.open(@file, 'r')

      zindex_loc = zdump.read(4).unpack('V')[0]
      loc = get_location(url, zdump, zindex_loc)
      return loc ? get_text(zdump, *loc) : nil
    end

    def get_text(zdump, block_offset, block_size, offset, size)
      text_compr = readloc( zdump, block_size, block_offset )
      text_uncompr = @compressor.uncompress( text_compr )
      return text_uncompr[offset, size]
    end

    def get_location(url, zdump, zindex_loc)
      md5 = MD5::md5(url).hexdigest 

      # converts the first four characters of the hex md5 digest into an integer
      firstfour = sprintf("%d", ("0x" + md5[0..3]) ).to_i                       

      # uses this number to calculate the location of the metaindex entry
      loc = (firstfour * 8) + zindex_loc                            

      # finds the location of the index entry
      start, size = readloc(zdump, 8, loc).unpack('V2')
      idx = readloc(zdump, size, start)

      # the index consists of a number of 32 byte entries. it sorts through
      # until it finds the right one.
      hex, *coordinates = idx.pop(32).unpack('H32V4') until ( hex == md5 || idx.empty? )
      return coordinates if hex == md5
    end
  end   

  class Writer
    include ZUtil
    attr_reader :location, :hardlinks

    @@entry = Struct.new(:uri, :block, :buflocation, :size, :md5)
    @@block = Struct.new(:number, :start, :size, :pages)                         

    # the uri to open, the minimum size of blocks, and zlib or bz2
    def initialize(file, blocksize = 900000, method = :bz2)
      @compressor = Compressor.new(method)
      @blocksize = blocksize
      @file = File.open(file, "w")
      @index = []         
      @cur_block, @buflocation, @size = 0, 0, 0
      @buffer = ''
      @location = 4 # (to hold start of index)
      @block_ary = [] 
      @hardlinks = {}
    end

    # adds a blob of text that will be acessible through a certain uri
    def add(uri, text)
      # if redirect, add to index and keep going
      entry = @@entry.new(uri, @cur_block, @buflocation, text.size)

      # calculate the md5 code, use the first four characters as the index
      entry.md5 = MD5::md5( entry.uri ).hexdigest
      firstfour = md5subset( entry.md5 )

      # add this entry to the index in the right place
      @index[firstfour] ||= []
      @index[firstfour] << entry

      # add to the buffer, and update the counter
      @buffer << text
      @buflocation += text.size

      flush_block if @buffer.size > @blocksize
    end

    # hardlinks the contents of one uri to that of another
    def add_hardlink(uri, targeturi)
      @hardlinks[uri] = targeturi
    end
    
    # finish up, process hardlinks, and write index to file
    def flush
      flush_block unless @buffer.empty?     
      process_hardlinks

      # writing the location of the archive (it's after the dump data)
      writeloc(@file, [@location].pack('V'), 0)                      

      indexloc = @location
      location = (65535*8) + indexloc

      p = File.open("zlog", "w")
      each_entry_with_index do |entry, idx|
        next if entry.nil?  

        writeloc(@file, [location, entry.size].pack('V2'), (idx * 8) + indexloc)
        writeloc(@file, entry, location)

        p << "*" * 80 << "\n" 
        p << "seek #{(idx*8) + indexloc} location #{location} size #{entry.size}" << "\n"
        p << unpack(entry).join(":") << "\n"

        location += entry.size
      end
      @file.close
      p.close
    end

    private
    # yields an entry that is ready to be written to the index
    def each_entry_with_index
      @index.each_with_index do |hash, idx|
        next if hash.nil?
        entry = ''  
        hash.each {|x| entry << pack(x.md5, @block_ary[x.block].start, @block_ary[x.block].size, x.buflocation, x.size) }
        yield entry, idx  
      end
    end

    # must be run after all the uris have been added, so their coordinates are known
    # adds entries for the hardlinks into the main index
    def process_hardlinks
      counter = 0
      @hardlinks.each do |file, target|
        counter += 1  

        # in case of recursive redirects, which shouldn't happen, but alas
        recursion = 0
        while @hardlinks[target] && recursion < 3
          recursion += 1
          target = @hardlinks[target]
        end

        # we'll just traverse the index and fetch the coords of the target
        md5, firstfour = md5_w_sub(file)
        md5_target, firstfour_target = md5_w_sub(target)

        entries = @index[firstfour_target]
        next if entries.nil?

        target = entries.select {|entry| entry.md5 == md5_target}

        # it really shouldn't be empty... if it is - the redirect is useless
        # anyway
        unless target.empty?         
          entry = target[0].dup  # so we don't overwrite the original

          # we just reuse the same entry, rewrite the md5, and add it to the index
          entry.md5 = md5
          @index[firstfour] ||= []        
          @index[firstfour] << entry
        end

      end
      @hardlinks = nil   # clean up some memory
    end

    # output the block in buffer to file, store the coords, and clean the buffer
    def flush_block
      bf_compr = @compressor.compress(@buffer)
      writeloc(@file, bf_compr, @location)
      @block_ary[@cur_block] = @@block.new(@cur_block, @location, bf_compr.size)

      @buffer = ''       
      @buflocation = 0
      @cur_block += 1                                           
      @location += bf_compr.size
    end  
  end
end                                        