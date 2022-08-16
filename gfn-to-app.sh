#!/bin/zsh
# resource_dasm from
# https://github.com/fuzziqersoftware/resource_dasm
# set -x
APPICON=;
############################
VERBOSE=$3
DEBUG=$4
[[ "$DEBUG" == "d" ]] && set -x;
[[ "$VERBOSE" == "-" ]] && VERBOSE=YES
############################
if [[ -n "${1}" ]] && [[ "$1" != "-" ]] ;
    then
        GAMEPATH="$1"
    elif [[ "$1" == "-" ]] || [[ -z "${1}" ]] ; then
        echo Enter Game Shortcut path: 
        read GAMEPATH
fi

if [[ -n "$2" ]]; then
        APPICON="$2"
fi

[ -z $GAMEPATH ] && echo "you cant leave the path empty. check readme \a\v" && exit 1;
inputFile="$(cat "$GAMEPATH")"
# if using bash then use a temporary variable
# cmsID="${inputFile%%&*}";
# then apply the second expansion
# x=${cmsID#*=}
# echo $x


gameID="${"${inputFile%%&*}"#*=}";

fileName="${GAMEPATH##*/}"
gameName="${fileName% on*}"

tempDIR=$(mktemp -d)

mkdir -p $tempDIR/"${gameName}".app
APPBUNDLE="$tempDIR/"${gameName}".app"

mkdir "${APPBUNDLE}"/Contents
CONTENTSDIR=""${APPBUNDLE}"/Contents"

mkdir "${CONTENTSDIR}"/MacOS
MACOSDIR=""${CONTENTSDIR}"/MacOS"

mkdir "${CONTENTSDIR}"/Resources
RESOURCESDIR=""${CONTENTSDIR}"/Resources"

####################
# Color codes
esc="$( echo -ne "\033" )"
escReset="${esc}[0m"
escUnder="${esc}[4m"
escBlue="${esc}[34m"
escGreen="${esc}[32m"
escRed="${esc}[31m"
escYellow="${esc}[33m"
escPurple="${esc}[35m"
escCyan="${esc}[36m"
#################
# getting the icon from original shortcut (method 1) found here: https://stackoverflow.com/q/73354927/11709309
# icns="$(xattr -px com.apple.ResourceFork "$GAMEPATH")" # grab the resource fork from the input file in hex format
# icns=${icns#*69 63 6E 73}   # using variable expansion delete the first 260 bytes including the magic number for icns.
# icns=$(echo "69 63 6E 73$icns") # add the magic number back
#
# getting the icon from original shortcut (method 2)
if [[ -z "$APPICON" ]] && [[ "$APPICON" != "-" ]];
    then
        echo "\vif you have a game icon put the location here (.icns file): "
        echo "if left empty then the icon from the shortcut will be used. \v"
        read APPICON
        if [[ -z "$APPICON" ]] || [[ "$APPICON" == "-" ]]; then      
                resource_dasm --target-type=icns "$GAMEPATH" $tempDIR/"${gameName}"-output 2>/dev/null 1>&2
                cp "$tempDIR/"${gameName}"-output"/*.icns "$RESOURCESDIR"/GameIcon.icns
            else
                cp "$APPICON" "$RESOURCESDIR"/GameIcon.icns
        fi
        elif  [[ "$APPICON" == "-" ]];
            then
                resource_dasm --target-type=icns "$GAMEPATH" $tempDIR/"${gameName}"-output 2>/dev/null 1>&2
                cp "$tempDIR/"${gameName}"-output"/*.icns "$RESOURCESDIR"/GameIcon.icns      
    else
        cp "$APPICON" "$RESOURCESDIR"/GameIcon.icns
fi

[ $VERBOSE ] && echo $escGreen"Creating Plist"$escReset
# create Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleDevelopmentRegion string English' "$CONTENTSDIR"/Info.plist 1>/dev/null
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string GameIcon.icns' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleInfoDictionaryVersion string 6.0' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 0.2' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 0.2-10' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :NSPrincipalClass string NSApplication' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string GFN' "$CONTENTSDIR"/Info.plist
/usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' "$CONTENTSDIR"/Info.plist

[ $VERBOSE ] && echo $escGreen"Creating Executable File"$escReset
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
        mv "$APPBUNDLE" /Applications/Games
fi
[ $VERBOSE ] && echo $escGreen"Setting Permissions"$escReset

[ $VERBOSE ] && echo $escGreen"Moving Application"$escReset

echo "Done \a"
