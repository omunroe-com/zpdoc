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

  Start = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="id" lang="id" dir="ltr">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      		<meta name="keywords" content="0-an,1,10-an,2,20-an,3,4,5,6,7,8" />
  		<link rel="search" type="application/opensearchdescription+xml" href="/w/opensearch_desc.php" title="Wikipedia (Bahasa Indonesia)" />
  		<link rel="copyright" href="../../../COPYING.html" />
      <title>TITLE - Wikipedia Indonesia, ensiklopedia bebas berbahasa Indonesia</title>
      POINTER
      <!--[if lt IE 5.5000]><style type="text/css">@import "../../../skins/monobook/IE50Fixes.css";</style><![endif]-->
      <!--[if IE 5.5000]><style type="text/css">@import "../../../skins/monobook/IE55Fixes.css";</style><![endif]-->
      <!--[if IE 6]><style type="text/css">@import "../../../skins/monobook/IE60Fixes.css";</style><![endif]-->
      <!--[if IE]><script type="text/javascript" src="../../../skins/common/IEFixes.js"></script>
      <meta http-equiv="imagetoolbar" content="no" /><![endif]-->    

       </head>
    <body
      class="ns-0">
      <div id="globalWrapper">
        <div id="column-content">
  	<div id="content">
  	  <a name="top" id="contentTop"></a>
  	        <h1 class="firstHeading">TITLE</h1>
  	  <div id="bodyContent">
  	    <h3 id="siteSub">Dari Wikipedia Indonesia, ensiklopedia bebas berbahasa Indonesia.</h3>
  	    <div id="contentSub"></div>'
  
  
  Ending = '<div class="visualClear"></div>
  	  </div>
  	</div>
        </div>
        <div id="column-one">
  	<div id="p-cactions" class="portlet">
  	  <h5>Views</h5>
  	  <ul>
  	    <li id="ca-nstab-main"
  	       class="selected"	       ><a href="#">Artikel</a></li><li id="ca-talk"
  	       class="new"	       ><a href="../../../PEMBICARA">Pembicaraan</a></li><li id="ca-current"
  	       	       ><a href="http://id.wikipedia.org/wiki/REVISI">Revisi sekarang</a></li>	  </ul>
  	</div>
  	<div class="portlet" id="p-logo">
  	    href="../../../index.html"
  	    title="Halaman Utama"></a>
  	</div>
  	<script type="text/javascript"> if (window.isMSIE55) fixalpha(); </script>
  		<div class="portlet" id="p-navigation">
  	  <h5>Navigasi</h5>
  	  <div class="pBody">
  	    <ul>
  	    	      <li id="n-mainpage"><a href="../../../index.html">Halaman Utama</a></li>
  	     	      <li id="n-portal"><a href="../../../k/o/m/Portal%7EKomunitas_38e4.html">Portal komunitas</a></li>
  	     	      <li id="n-currentevents"><a href="../../../p/e/r/Portal%7EPeristiwa_terkini_aaf9.html">Peristiwa terkini</a></li>
  	     	      <li id="n-recentchanges"><a href="../../../p/e/r/Istimewa%7EPerubahanterbaru_6a48.html">Perubahan terbaru</a></li>
  	     	      <li id="n-randompage"><a href="../../../h/a/l/Istimewa%7EHalamansembarang_e9da.html">Halaman sembarang</a></li>
  	     	      <li id="n-help"><a href="../../../i/s/i/Bantuan%7EIsi_fd23.html">Bantuan</a></li>
  	     	      <li id="n-sitesupport"><a href="http://wikimediafoundation.org/wiki/Penggalangan_dana">Donasi</a></li>
  	     	      <li id="n-Warung-Kopi"><a href="../../../w/a/r/Wikipedia%7EWarung_Kopi_db6c.html">Warung Kopi</a></li>
  	     	    </ul>
  	  </div>
  	</div>
  		<div id="p-search" class="portlet">
  	  <h5><label for="searchInput">Cari</label></h5>
  	  <div id="searchBody" class="pBody">
  	    <form action="javascript:goToStatic(3)" id="searchform"><div>
  	      <input id="searchInput" name="search" type="text"
  	        accesskey="f" value="" />
  	      <input type="submit" name="go" class="searchButton" id="searchGoButton"
  	        value="Tuju ke" />
  	    </div></form>
  	  </div>
  	</div>
  	<div id="p-lang" class="portlet">
  	  <h5>Bahasa lain</h5>
  	  <div class="pBody">
  	    <ul>
  	      	      <li>
  	      <OTHERLANG>
  	      </li>
  	      	    </ul>
  	  </div>
  	</div>
  	      </div><!-- end of the left (by default at least) column -->
        <div class="visualClear"></div>
        <div id="footer">

  	  	  	  <li id="f-copyright">Seluruh teks tersedia sesuai dengan <a href="../../../COPYING.html" class="external " title="../../../COPYING.html" rel="nofollow">GNU Free Documentation License</a><br />Wikipedia&reg; adalah merek dagang terdaftar dari <a href="http://www.wikimediafoundation.org">Wikimedia Foundation, Inc</a>.<br /></li>	  <li id="f-about"><a href="../../../p/e/r/Wikipedia%7EPerihal_3095.html" title="Wikipedia:Perihal">Tentang Wikipedia</a></li>	  <li id="f-disclaimer"><a href="../../../p/e/n/Wikipedia%7EPenyangkalan_umum_413f.html" title="Wikipedia:Penyangkalan umum">Penyangkalan</a></li>	  	</ul>
        </div>
      </div>
    </body>
  </html>'
end