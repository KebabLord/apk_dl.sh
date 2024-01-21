## Preview:
```
λ ./apkdl.sh telegram
1) Telegram X
2) Telegram
3) Telegram (Google Play version)
4) Plus Messenger
5) Telegram Beta
6) Shurgram

Select one from above: 2

Selected: Telegram
 - Scraping the file id..    OK
 - Scraping the file path..  OK
 - Downloading the APK
telegram.apk                   100%[==================================>]  70.64M  4.81MB/s    in 16s     
Do you want to install the apk? (y/n): n
```
## Usage
if on termux, make sure to give it "install unknown apps" permission if you don't have root.
```bash
# Install dependencies
pkg install wget curl
# Download the script
wget -O apk_dl.sh https://github.com/KebabLord/apk_dl.sh/raw/main/apk_dl.sh
# Give it execute permission
chmod +x apk_dl.sh
# Now you can run it with ./apk_dl.sh "application name"
```

## Why not ApkMirror?
Because apkmirror has cloudflare protection making it impossible to scrape the download url, without using a webdriver (bloat).
Uptodown on the other hand, is curl friendly.

## Is Uptodown secure?
Yes, in fact even more legit than apkmirror. It's actually a legit [company](https://www.linkedin.com/company/uptodown/) located in Spain. Also I compared the md5 hashes of some random app apks with the ones on apkmirror, they're the same.
