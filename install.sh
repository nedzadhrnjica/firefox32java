#!/bin/bash

# This installer will prepare 32bit firefox with Java Plugin/applet
#
# Created on 05.05.2017 by Nedzad Hrnjica
# Prepared on 'Ubuntu 16.04.2 LTS, xenial', 'Linux laptop.nedzadhrnjica.com 4.4.0-77-generic #98-Ubuntu SMP Wed Apr 26 08:34:02 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux'

# Note:
# - You must manually download Java... link will be provided to you by install script...
# - latest working version of firefox will be automatically downloaded

[[ -d "firefox/" ]] && echo "ERROR: subdirectory 'firefox/' already exists. Exiting." && exit 1

JREFILE=$(\ls -1 jre*.tar.gz 2>/dev/null | head -n 1)
if [[ ! -s "$JREFILE" ]]; then
  echo "Download 'jre-...-linux-i586.tar.gz' from 'http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html'."
  echo "Please download file to '$(pwd)/'."
  echo "waiting..."
  echo ""

  which xdg-open >/dev/null && xdg-open "http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html" > /dev/null 2>&1 &
  while [[ ! -s "$JREFILE" ]]; do
    JREFILE=$(\ls -1 jre*.tar.gz 2>/dev/null | head -n 1)
  done
  if [[ -n "$JREFILE" ]]; then
    echo "Thanks, let's continue with installation...."
  else
    echo "Interrupted !?"
    exit 2
  fi
fi

# Version 52.0 already does not work with Java plugin
wget -nc https://ftp.mozilla.org/pub/firefox/releases/51.0.1/linux-i686/en-US/firefox-51.0.1.tar.bz2

# Do we have required i386 libraries installed:

TESTLIBS=
TESTLIBS=$(echo "$TESTLIBS" ; dpkg --list | grep "libgtk-3-0:i386" || echo "MISSING")
TESTLIBS=$(echo "$TESTLIBS" ; dpkg --list | grep "libdbus-glib-1-2:i386" || echo "MISSING")
TESTLIBS=$(echo "$TESTLIBS" ; dpkg --list | grep "libxtst6:i386" || echo "MISSING")

TESTLIBS=$(echo "$TESTLIBS" | grep "MISSING")
if [[ -n "$TESTLIBS" ]]; then
  echo "Installing required i386 modules on Ubuntu... please enter your password to elevate with sudo to install required modules..."
  sudo apt -y install libgtk-3-0:i386
  sudo apt -y install libdbus-glib-1-2:i386
  sudo apt -y install libxtst6:i386

  echo "Removing sudo gathered privileges..."
  sudo -k
fi

# Extract application and plugin

tar -xvf firefox*.bz2
tar -xvf jre*.tar.gz

mv jre*/ jre/
mv jre/ firefox/

cd firefox/

mkdir -p browser/plugins/
cd browser/plugins/
ln -s "$(pwd)/../../jre/lib/i386/libnpjp2.so" .
cd ../../

echo "\"$(pwd)/firefox\" --no-remote --profile \"$(pwd)/profile/\" > /dev/null 2>&1" > start.sh
chmod +x start.sh

# disable updates (prevent from creating subdirectory 'updates/')
touch updates

# local profile:
mkdir profile/

echo "wait...wait...I will open firefox, wait 5 seconds, and close it automatically... preparing...preparing..."
./firefox --no-remote --profile profile/ > /dev/null 2>&1 &
MYPID=$!
while [[ ! -f "profile/pluginreg.dat" ]]; do sleep 1; done
sleep 5
kill $MYPID

# disable 64bit java plugin automatically added to firefox
sed -i -e "s#/amd64/#/amd64.disabled/#" profile/pluginreg.dat

# disable asking to become default browser

echo ' user_pref("browser.shell.checkDefaultBrowser", false);' >> profile/prefs.js
echo ' user_pref("plugin.state.java", 2);' >> profile/prefs.js

cd ..

echo ""
echo "That's it!"
echo "You can now start your firefox32 with java plugin using:"
echo ""
echo "firefox/start.sh"

