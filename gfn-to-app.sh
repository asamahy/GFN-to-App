#!/bin/zsh
# resource_dasm from
# https://github.com/fuzziqersoftware/resource_dasm
# set -x
if [[ -n "${1}" ]]; then
    GAMEPATH="$1"
    else
    echo Enter Game Shortcut path: 
    read GAMEPATH
fi

# in="$1"
inputFile="$(cat "$GAMEPATH")"
# if using bash then use a temporary variable
# cmsID="${inputFile%%&*}";
# then apply the second expansion
# x=${cmsID#*=}
# echo $x
gameID="${"${inputFile%%&*}"#*=}";
# echo $gameID
# echo
fileName="${GAMEPATH##*/}"
gameName="${fileName% on*}"
# echo filename: $fileName
# echo gameName: $gameName
read ok
tempDIR=$(mktemp -d)

mkdir -p $tempDIR/"${gameName}".app
APPBUNDLE="$tempDIR/"${gameName}".app"

mkdir "${APPBUNDLE}"/Contents
CONTENTSDIR=""${APPBUNDLE}"/Contents"

mkdir "${CONTENTSDIR}"/MacOS
MACOSDIR=""${CONTENTSDIR}"/MacOS"

mkdir "${CONTENTSDIR}"/Resources
RESOURCESDIR=""${CONTENTSDIR}"/Resources"

# echo made app
# read ok

echo "if you have a game icon put the location here (.icns file): "
echo "if left empty then the icon from the shortcut will be used. \v"
read APPICON

# get the icon from original shortcut (method 1) found here: https://stackoverflow.com/q/73354927/11709309
# icns="$(xattr -px com.apple.ResourceFork "$GAMEPATH")" # grab the resource fork from the input file in hex format
# icns=${icns#*69 63 6E 73}   # using variable expansion delete the first 260 bytes including the magic number for icns.
# icns=$(echo "69 63 6E 73$icns") # add the magic number back
#
# get the icon from original shortcut (method 2)
set -x
if [ -z $APPICON ];
    then      
        resource_dasm --target-type=icns "$GAMEPATH" $tempDIR/"${gameName}"-output
        cp "$tempDIR/"${gameName}"-output"/*.icns "$RESOURCESDIR"/GameIcon.icns
    else
        cp "$APPICON" "$RESOURCESDIR"/GameIcon.icns
fi
# read ok
# create Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleDevelopmentRegion string English' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string GameIcon.icns' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleInfoDictionaryVersion string 6.0' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 0.2' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 0.2-10' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :NSPrincipalClass string NSApplication' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string GFN' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' "$CONTENTSDIR"/Info.plist

# echo made plist
# read ok


# create the Executable file
cat << ENDOFSCRIPT > "$CONTENTSDIR"/MacOS/GFN
#!/bin/zsh

open "/Applications/GeForceNOW.app" --args --url-route="#?cmsId=${gameID}&launchSource=External"
ENDOFSCRIPT
# echo waiting
# read ok
# make it executable
chmod u+x "$CONTENTSDIR"/MacOS/GFN

# move it to Application
if [ -f "/Applications/"$APPBUNDLE"" ]; then
        echo "File \""$APPBUNDLE"\" already exists"
        exit 1
    else
        mv "$APPBUNDLE"/ /Applications/Games
fi


echo Done
