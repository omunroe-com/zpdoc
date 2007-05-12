# Provides compression and uncompression features for zipdoc program. Can be transparently
# exchanged with other compression methods, as long as the same is used for packing and
# accessing (unpacking). Must operate so that each chunk can be independently unpacked.

require 'zlib'

module ZCompress
  def self.uncompress(txt)
    Zlib::Inflate.new.inflate(txt)
  end

  def self.compress(txt)
    Zlib::Deflate.new.deflate(txt, Zlib::FINISH)
  end
end