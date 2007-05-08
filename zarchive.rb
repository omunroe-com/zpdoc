# Library for accessing a Wikipedia zdump file. 
# 
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
    @zdump_loc = @zdump.read(4).unpack('V')[0]
  end

  def get_article(url)      
    loc = get_location(url)
    return loc ? get_text(*loc) : nil
  end

  private
  def get_text(block_offset, block_size, offset, size)
    return ZCompress.uncompress( ZUtil::readloc( @zdump, block_size, block_offset ))[offset, size]
  end
    
  def get_location(url)
    md5 = Digest::MD5.hexdigest(url)
    firstfour = sprintf("%d", ("0x" + md5[0..3]) ).to_i
    loc = (firstfour * 8) + @zdump_loc
    start, size = ZUtil::readloc(@zdump, 8, loc).unpack('V2')
    idx = ZUtil::readloc(@zdump, size, start)
    hex, *coordinates = idx.pop(32).unpack('H32V4') until ( hex == md5 || idx.empty? )
    return coordinates if hex == md5
  end
end                     
