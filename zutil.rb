# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Just a few utility functions that are used in several places
# I started out with having these as extensions of String and IO, but 
# I guess that's not very nice in a library? I keep the pop though -
# cannot believe it isn't standard.

require 'digest'
module ZUtil
  def unpack(string)
    return string.unpack('H40V4' * (string.size/36))
  end  

  def pack(sha1, bstart, bsize, start, size)
    return [sha1, bstart, bsize, start, size].pack('H40V4')
  end

  def sha1subset(four, no = 4)
    sprintf("%d", "0x" + four[0..(no-1)]).to_i                                                  
  end                                                        
  
  def sha1_w_sub(string, no = 4)
    sha1 = Digest::SHA1.hexdigest( string )
    firstfour = sha1subset( sha1, no )
    return sha1, firstfour
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

  module_function :unpack, :pack, :sha1subset, :writeloc, :readloc, :strip_whitespace
  module_function :url_unescape, :npp, :sha1_w_sub
end

class String
  def pop(number = 1)
    slice!(-number..-1)
  end
end       
