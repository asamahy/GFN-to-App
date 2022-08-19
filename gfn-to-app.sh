#!/bin/zsh
# resource_dasm from
# https://github.com/fuzziqersoftware/resource_dasm
############################
VERBOSE=$3
DEBUG=$4
[[ "$DEBUG" == "d" ]] && set -x;
{ [[ "$VERBOSE" == "-" ]] && VERBOSE=YES } || VERBOSE='';
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
#
# if using bash then use a temporary variable
# cmsID="${inputFile%%&*}";
# then apply the second expansion
# x=${cmsID#*=}
# echo $x
#################
# Setting Variables
#################
tempDIR=$(mktemp -d)
gameID="${"${inputFile%%&*}"#*=}";
fileName="${GAMEPATH##*/}"
gameName="${fileName% on*}"
mkdir -p $tempDIR/"${gameName}".app
APPBUNDLE="$tempDIR/"${gameName}".app"
mkdir "${APPBUNDLE}"/Contents
CONTENTSDIR=""${APPBUNDLE}"/Contents"
mkdir "${CONTENTSDIR}"/MacOS
MACOSDIR=""${CONTENTSDIR}"/MacOS"
mkdir "${CONTENTSDIR}"/Resources
RESOURCESDIR=""${CONTENTSDIR}"/Resources"
ICONFORMAT='png'
GAMESDIR="/Applications/Games"
#####################
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
isDirExist(){
    [[ ! -d "$1" ]] && mkdir "$1"
}
extractIcon(){
[[ -f $(which resource_dasmm) ]] && DASM=true;
# $1="$GAMEPATH" $2=$tempDIR
isDirExist "${2}-output"
    { [[ $DASM == "true" ]] && resource_dasm --target-type=icns "$1" "${2}"-output 2>/dev/null 1>&2; } || \
    {
        # getting the icon from original shortcut (method 1) found here: https://stackoverflow.com/q/73354927/11709309
        icns="$(xattr -px com.apple.ResourceFork "$1")" # grab the resource fork from the input file in hex format
        icns=${icns#*69 63 6E 73}   # using variable expansion delete the first 260 bytes including the magic number for icns.
        icns=$(echo "69 63 6E 73$icns") # add the magic number back
        echo "$icns" | xxd -p -r > "${2}-output/GameIcon.icns"
    }
}
cleanup(){
  [ $VERBOSE ] && echo -e $escRed"Removing Temp Files...."$escReset
#   rm -R "$tempDIR" || echo "Unable to Remove Temp Directory"
  exit 1
}
convertIcon(){
    hasAlpha="$(sips -g hasAlpha "$1" | awk -F "hasAlpha: " '{getline; print $2}')"
   if [[ "${hasAlpha}" == "yes" ]]; then
    ICONFORMAT="png"
    else
    ICONFORMAT="png"
   fi
    # if icon is in other formats then convert it to png first then use it
    isDirExist "${2}"
    [[ $DASM != "true" ]] && sips -s format $ICONFORMAT -s formatOptions best -z 512 512 "$1" --out "${2}/GameIcon.icns" 1>/dev/null 2>&1 && APPICON="${2}/GameIcon.icns" || \
    APPICON=${2}
}
findIcon(){
    find "${HOME}/Pictures/Icons/Games" -iname "${1}*" | head -1
}
#############
# cleanup trigger
trap cleanup 1 2 3 6
#
# Game existance check
[ $VERBOSE ] && echo ${escGreen}Game is$escReset $escCyan"$gameName"$escReset
[[ -d "${GAMESDIR}/"${APPBUNDLE##*/}"" ]] && {echo $escRed""${APPBUNDLE##*/}" already exists \a"$escReset && cleanup }
#
[ $VERBOSE ] && echo $escGreen"Extracting Game Icon"$escReset
# look for icon with game name
if [[ "${2}" == "f" ]]; then
        APPICON=$(findIcon ${gameName};)
        { { [[ ${APPICON##*.} == "png" ]] || [[ ${APPICON##*.} == "icns" ]] } && echo $escCyan"Icon Found"$escReset } || { echo $escRed"No Icon Found"$escReset && APPICON="" }
        read ok
fi
# getting the icon from original shortcut (method 2)
if [[ -z "$APPICON" ]]; then
        echo "\vif you have a game icon put the location here (.icns file): "
        echo "if left empty then the icon from the shortcut will be used. \v"
        read APPICON
        {[[ -z $APPICON ]] && extractIcon "$GAMEPATH" $tempDIR/"${gameName}" && convertIcon "$tempDIR/"${gameName}"-output"/*.icns "$tempDIR/"${gameName}"-output"} || convertIcon "$APPICON" "$tempDIR/"${gameName}"-output";
        cp "${APPICON%*/}"/*.icns "$RESOURCESDIR"/GameIcon.icns || { echo $escRed"Error Copying Icon"$escReset && cleanup }
elif [[ "$APPICON" == "-" ]]; then
        extractIcon "$GAMEPATH" $tempDIR/"${gameName}" && convertIcon "$tempDIR/"${gameName}"-output"/*.icns "$tempDIR/"${gameName}"-output"
        cp "${APPICON}" "$RESOURCESDIR"/GameIcon.icns || { echo $escRed"Error Copying Icon"$escReset && cleanup }
    else
        convertIcon "$APPICON" "$tempDIR/"${gameName}"-output";
        cp "$APPICON" "$RESOURCESDIR"/GameIcon.icns || { echo $escRed"Error Copying Icon"$escReset && cleanup }
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
[[ ! $? ]] && { echo $escRed"Creating Executable Failed. Check Debug"$escReset && cleanup && exit 1 }
[ $VERBOSE ] && echo $escGreen"Setting Permissions"$escReset
# make it executable
chmod u+x "$CONTENTSDIR"/MacOS/GFN 2>/dev/null || { echo $escRed"Setting Permissions Failed. Check Debug"$escReset && cleanup && exit 1 }

[ $VERBOSE ] && echo $escGreen"Moving Application"$escReset
# move Game to Applications/Games
isDirExist "${GAMESDIR}"
{mv "$APPBUNDLE" ${GAMESDIR} && echo $escGreen"[*]Done! $gameName app created successfully \a"$escReset}|| { echo $escRed"\vMoving Failed. App might already exist. Check Debug"$escReset && cleanup && exit 1 }


cleanup;

