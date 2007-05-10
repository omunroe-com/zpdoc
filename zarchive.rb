# Library for accessing a zip-doc zdump file. 
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
# 
# Usage example: 
# require 'zarchive'
# archive = ZArchive.new('eo.zdump')
# puts ZArchive.get_article('eo/o/s/l/Oslo.html')

require 'zcompress'
require 'digest'
require 'zutil'

class ZArchive               
  def initialize(file)
    @zdump = File.open(file, 'r')

    # the index is located after the dunp file, and the location is given by the
    # first four bytes of the file
    @zindex_loc = @zdump.read(4).unpack('V')[0]
  end

  def get_article(url)      
    loc = get_location(url)
    return loc ? get_text(*loc) : nil
  end

  private
  def get_text(block_offset, block_size, offset, size)
    text_compr = ZUtil::readloc( @zdump, block_size, block_offset )
    text_uncompr = ZCompress.uncompress( text_compr )
    return text_uncompr[offset, size]
  end
    
  def get_location(url)
    md5 = Digest::MD5.hexdigest(url) 

    # converts the first four characters of the hex md5 digest into an integer
    firstfour = sprintf("%d", ("0x" + md5[0..3]) ).to_i                       
    
    # uses this number to calculate the location of the metaindex entry
    loc = (firstfour * 8) + @zindex_loc                            
    
    # finds the location of the index entry
    start, size = ZUtil::readloc(@zdump, 8, loc).unpack('V2')
    idx = ZUtil::readloc(@zdump, size, start)

    # the index consists of a number of 32 byte entries. it sorts through
    #until it finds the right one.
    hex, *coordinates = idx.pop(32).unpack('H32V4') until ( hex == md5 || idx.empty? )
    return coordinates if hex == md5
  end
end                     
