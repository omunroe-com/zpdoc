# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

module HTMLShrinker_data
  Replacements = {
    # 'class="image"'                                    => 3.chr + 2.chr,
    # 'style="background-color:'                         => 3.chr + 3.chr,
    # 'style="vertical-align:'                           => 3.chr + 4.chr,
    # '<td style="white-space: nowrap;">'                => 3.chr + 5.chr,
    # '<a href="../../../'                               => 3.chr + 6.chr,
    # '<td align='                                       => 3.chr + 7.chr,
    # '<p>'                                              => 4.chr,
    # '<h2>'                                             => 5.chr,
    # '</h2>'                                            => 6.chr,
    # '<span class="'                                    => 7.chr,
    # '</span>'                                          => 8.chr,
    # '<a href="http://commons.wikimedia.org/'           => 9.chr,
    # '<tr>'                                             => 14.chr,
    # '<table align="'                                   => 15.chr,
    # 'title="'                                          => 16.chr,
    # '</a>'                                             => 17.chr,
    # '<div class="'                                     => 18.chr,
    # '<span dir='                                       => 19.chr,
    # '</span'                                           => 20.chr,
    # '</div'                                            => 21.chr,
    # '<b>'                                              => 22.chr,
    # '</b>'                                             => 23.chr,        
    # '<li class="toclevel-1"><a href="'                 => 24.chr,
    # '<td style="white-space: nowrap;">'                => 25.chr,
    # '<div style="text-align: right;">'                 => 26.chr,
    # 'wikipedia.org'                                    => 27.chr,
    # 'align="center"'                                   => 28.chr,
    # '<div style="width:50%; float:right;">'            => 29.chr,
    # '<th align="left" style="vertical-align: top;">'   => 30.chr,
    # '<div style="margin-left:'                         => 31.chr,
  }

  
  To_be_replaced = /\<script type\="text\/javascript" src\="\.\/skins\/common\/wikibits.js">(.*?)\/\*\]\]>\*/m

end
