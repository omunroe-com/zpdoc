# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

module HTMLShrinker_data
  Replacements = {
    '<a href="../../../'  => 2.chr,
    '<td align='          => 3.chr,
    '<p>'                 => 4.chr,
    '<h2>'                => 5.chr,
    '</h2>'               => 6.chr,
    '<span class="'       => 7.chr,
    '</span>'             => 8.chr,
    '<tr>'                => 14.chr,
    '<table align="'      => 15.chr,
    'title="'             => 16.chr,
    '</a>'                => 17.chr,
    '<div class="'        => 18.chr,
    '<span dir='          => 19.chr,
    '</span'              => 20.chr,
    '</div'               => 21.chr,
    '<b>'                 => 22.chr,
    '</b>'                => 23.chr,
  }
  
  To_be_replaced = /\<script type\="text\/javascript" src\="\.\/skins\/common\/wikibits.js">(.*?)\/\*\]\]>\*/m

end
