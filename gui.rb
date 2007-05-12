# Part of the zip-doc suite
# By Stian Haklev (shaklev@gmail.com), 2007
# Released under MIT and GPL licenses

require 'tk' 
require 'tk/wm'
class GUI

  def initialize
    ph = { 'padx' => 10, 'pady' => 10 }     # common options
    open = proc {`open http://localhost:2042/`}
    leave = proc {
      H.stop
      exit(0)
    }
    
    root = TkRoot.new { title "Wikipedia Offline Server" }
#    top::Wm.focusmodel('active')
    top = TkFrame.new(root)
    TkLabel.new(top) {text    'The Wikipedia Server is now running.' ; pack(ph) }
    TkLabel.new(top) {text    'It is available through http://localhost:2042/' ; pack(ph) }

    TkButton.new(top) {text 'Open default webbrowser'; command open; pack ph}
    TkButton.new(top) {text 'Exit'; command leave; pack ph}
    top.pack('fill'=>'both', 'side' =>'top')
  end
end


