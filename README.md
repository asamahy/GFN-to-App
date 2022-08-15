
# GFN-to-App 📝  
Creates app bundles from Geforce Now game shortcuts.
uses the game's id extracted from the shortcut 
and passing it as an argument to the geforce now app located in `/Applications/GeForceNOW.app`

This is so you can access the Game from launchpad or even Steam.
 
## Usage  
The Script runs Interactively and via CLI. 

To run interactively simply execute the script 

`./gfn-to-app.sh`.

If you get permissions error make sure the script is executable by running:

`chmod u+x gfn-to-app.sh`

As for running from CLI you can specify both or either of the inputs; 
otherwise, the shell will ask you to input them. 

you can plase a single `-` to skip the prompt for the icon file to use the one made by the geforce 
shortcut automatically; However, using `-` in place of the game shortcut path will prompt the shell to ask for it.
(the geforce game shortcut path can not be empty)
~~~shell  
 ./gfn-to-app "path/to/shortcut/file.gfnpc" "path/to/icon.icns"
~~~  
 
## Examples  
~~~shell  
  ./gfn-to-app - -
  ./gfn-to-app "/Users/asamahy/Desktop/FrostPunk on GeForce NOW.gfnpc" -
  ./gfn-to-app "/Users/asamahy/Desktop/FrostPunk on GeForce NOW.gfnpc" "icon.icns"
  ./gfn-to-app - "icon.icns"
~~~  
