#!/bin/sh

# Detect FreeBSD and set appropriate skel directory
if [ "$(uname -s)" = "FreeBSD" ]; then
	SKEL_DIR="/usr/local/etc/skel"
else
	SKEL_DIR="/etc/skel"
fi

echo "Copying initial settings from $PWD/home"
if [ -d "$HOME/Library" ];then
	echo "$HOME/Library exists already, please make sure it is up to date"
else
	cp -R "$SKEL_DIR/Library" $HOME/
fi

cp -Rn "$SKEL_DIR/.config" $HOME/

if [ -f "$HOME/.xinitrc" ];then
	echo "$HOME/.xinitrc exists already, will not overwrite!"
else
	cp ./extra/xinitrc $HOME/.xinitrc
fi
