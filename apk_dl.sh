#!/bin/bash
# Cli tool to download & Install apks from UpToDown, by KebabLord.
# NOTE: Don't forget to uncomment one of the last lines to enable installing the APK.
# DEPENDS: wget, curl, awk, grep

# Set default values
is_list=false
is_first=false
is_yes=false
res_limit=6

help_msg="USAGE: $0 <args> <app_name>

(no arg) : Prompts user to select one of the applications from list.
-l : Just list the available applications, don't install anything.
-f : Directly select the first result and install.
-y : Answer yes to \"Are you sure\" prompt.
-n : Select n'th result from list and install.
-a : Show all results, Don't limit results to $res_limit.
-h : Show this help message."

while getopts "lyan:fh" opt; do
    case $opt in
        l) is_list=true;;
        y) is_yes=true;;
        a) res_limit=36;;
        n) custom_index="$OPTARG";;
        f) res_limit=1;;
        *) echo "$help_msg"; exit 0;;
    esac
done
shift $((OPTIND-1))
app="$1"
[ -z "$app" ] && echo "$help_msg" && exit 1

# Function to send initial request.
send_req() {
    # First param being the mirror subdomain, 2nd param is the application name to be searched.
    curl -m 9 "https://$1.uptodown.com/android/search" -X POST -H \
        'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0' -H \
        'Referer: https://en.uptodown.com/' --data-raw "singlebutton=&q=$2" 2>/dev/null
}

# Try different mirrors until one bypasses 500,503 and 504.
mirrors="tr en de es fr it pt zh ar id ko"
for mirror in $mirrors; do
    req=$(send_req $mirror $app) || continue
    grep "Error 503 first byte timeout\|Uptodown 500\|504 Gateway Time" &>/dev/null <<< "$req" && continue
    break
done

# Parse the results into url+title, exit if grep fails.
results=$(echo "$req" | grep -Po 'https:\/\/[a-z_-]+?\.[a-z][a-z].uptodown.com\/android" title="[^<>"]+')
[[ $? != 0 ]] && echo "ERROR: Couldn't find the application." && exit 1
amount=$(echo "$results" | wc -l)

# Print titles so user can choose one, also add each item to the lists.
i=1
while IFS= read -r res; do
    urls[$i]="$(awk -F '" title="[^ ]+ ' '{print $1}' <<< "$res")"
    titles[$i]="$(awk -F '" title="[^ ]+ ' '{print $2}' <<< "$res")"
    [ $amount -gt 1 ] && (! $is_first) && [ -z $custom_index ] && echo "$i) ${titles[$i]}"
    [[ "$i" == "$res_limit" ]] && break
    ((i++))
done <<< "$results"

# If "only list, not install" is enabled, quit.
$is_list && exit 0

# If "use directly the first result" or more than one result, show "choose" prompt.
if [[ "$custom_index" == ?(-)+([0-9]) ]]; then
    index=$custom_index
elif [ $res_limit -ne 1 ] || [ -z "${titles[2]}" ]; then
    echo -ne "\nSelect one from above: "
    read -r index
    echo
    [[ "$index" != ?(-)+([0-9]) ]] && ( echo Not a valid number. ; exit 1 )
else
    index=1
fi

app_url=${urls[$index]}
app_title=${titles[$index]}
echo -e "Selected: $app_title"

# Scrape file id by visiting the "downloads" page.
echo -en " - Scraping the file id..    "
src=$(curl "$app_url/download" 2>/dev/null | grep -Po 'data-file-id="\d+"')
[[ $? -gt 0 ]] && echo -e "\r - Couldn't parse the file id." && exit 1
file_id=$(awk -F '="' '{print $2}' <<< "$src" | tr -d \")
echo "OK"

# Scrape file path by visiting "downloading" page
echo -en " - Scraping the file path..  "
filepath="$(curl "$app_url/post-download/$file_id" 2>/dev/null | grep -Po 'post-download" data-url="[^"> ]+' | awk -F 'data-url="' '{print $2}')"
echo "OK"

# Download the file.
echo " - Downloading the APK"
wget -O "$app.apk" -q --show-progress "https://dw.uptodown.com/dwn/$filepath"

# Install it (uncomment one of the below)
($is_yes || (read -p "Do you want to install the apk? (y/n): " yn && [[ $yn == y ]])) &&
# su -c pm install "$query.apk" # If device is rooted, doesn't ask for confirmation. 
# termux-open "$query.apk"      # If device is not rooted.
exit $?
