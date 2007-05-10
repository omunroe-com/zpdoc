# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Just a few utility functions that are used in several places
# I started out with having these as extensions of String and IO, but 
# I guess that's not very nice in a library? I keep the pop though -
# cannot believe it isn't standard.

module ZUtil
  def self.unpack(string)
    return string.unpack('H32V4' * (string.size/32))
  end  

  def self.pack(md5, bstart, bsize, start, size)
    return [md5, bstart, bsize, start, size].pack('H32V4')
  end

  def self.md5subset(four)
    sprintf("%d", "0x" + four[0..3]).to_i                                                  
  end

  def self.writeloc(file, text, offset)
    file.seek offset
    file.write text
  end

  def self.readloc(file, size, offset) 
    file.seek(offset)
    file.read(size)
  end

  def self.strip_whitespace(txt)
    return txt.gsub(/\t/, " ").gsub('  ',' ').gsub("\n", '') 
  end

end

class String
  def pop(number = 1)
    self.slice!(-number..-1)
  end
end       
