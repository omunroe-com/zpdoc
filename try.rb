files = ['id/skins/htmldump/main.css',
'id/skins/common/commonPrint.css',
'id/skins/common/wikibits.js',
'id/skins/htmldump/md5.js',
'id/skins/htmldump/utf8.js',
'id/skins/htmldump/lookup.js',
'id/raw/gen.js',
'id/raw/MediaWiki~Common.css',
'id/raw/MediaWiki~Monobook.css',
'id/raw/gen.css',
'id/skins/common/images/poweredby_mediawiki_88x31.png',
'id/images/wikimedia-button.png']

require 'zarchive'
f = ZArchive.new('id.z')
files.each do |fil|
  puts fil
  puts f.get_article(fil).size
  end
  