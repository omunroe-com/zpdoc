# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Just a few utility functions that are used in several places
# I started out with having these as extensions of String and IO, but 
# I guess that's not very nice in a library? I keep the pop though -
# cannot believe it isn't standard.

module ZUtil
  def unpack(string)
    return string.unpack('H32V4' * (string.size/32))
  end  

  def pack(md5, bstart, bsize, start, size)
    return [md5, bstart, bsize, start, size].pack('H32V4')
  end

  def md5subset(four)
    sprintf("%d", "0x" + four[0..3]).to_i                                                  
  end

  def writeloc(file, text, offset)
    file.seek offset
    file.write text
  end

  def readloc(file, size, offset) 
    file.seek(offset)
    file.read(size)
  end

  def strip_whitespace(txt)
    return txt.gsub(/\t/, " ").gsub('  ',' ').gsub("\n", '') 
  end

  # from http://railsruby.blogspot.com/2006/07/url-escape-and-url-unescape.html
  def url_unescape(string)
    string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
      [$1.delete('%')].pack('H*')
    end
  end                           
             
  def npp(num)
    sprintf("%.2f" % num)
  end

  module_function :unpack, :pack, :md5subset, :writeloc, :readloc, :strip_whitespace
  module_function :url_unescape, :npp
end

class String
  def pop(number = 1)
    slice!(-number..-1)
  end
end       
