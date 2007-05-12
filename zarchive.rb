# Library for accessing a zip-doc zdump file. 
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
# 
# Usage example: 
# require 'zarchive'
# archive = ZArchive.new('eo.zdump')
# puts ZArchive.get_article('eo/o/s/l/Oslo.html')

%w(md5 zcompress zutil).each {|x| require x} 

class ZArchive               
  include ZUtil
  def initialize(file)
    @file = file             
  end

  def get_article(url)
    zdump = File.open(@file, 'r')

    zindex_loc = zdump.read(4).unpack('V')[0]
    loc = get_location(url, zdump, zindex_loc)
    puts loc ? loc.join(":") : "Couldn't find #{url}"
    return loc ? get_text(zdump, *loc) : nil
  end

  private
  def get_text(zdump, block_offset, block_size, offset, size)
    text_compr = readloc( zdump, block_size, block_offset )
    text_uncompr = ZCompress.uncompress( text_compr )
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
    #until it finds the right one.
    hex, *coordinates = idx.pop(32).unpack('H32V4') until ( hex == md5 || idx.empty? )
    return coordinates if hex == md5
  end
end                     