# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses
#
# Provides compression and uncompression features for zipdoc program. Can be transparently
# exchanged with other compression methods, as long as the same is used for packing and
# accessing (unpacking). Must operate so that each chunk can be independently unpacked.

require 'bz2'

module ZCompress
  def self.uncompress(txt)
    BZ2::Reader.new(txt).read
  end

  def self.compress(txt)
    (BZ2::Writer.new << txt).flush
  end
end