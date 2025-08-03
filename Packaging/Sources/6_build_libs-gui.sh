#!/bin/sh -e

. ../environment.sh
. "${GNUSTEP_MAKEFILES}/GNUstep.sh"
. ${DEST_DIR}/etc/profile.d/nextspace.sh

if ! [ -z $IS_FREEBSD ]; then
  if ! [ "$DEST_DIR" = "/usr/local" ]; then
    printf "%sYou are on FreeBSD and don't have DEST_DIR set to '/usr/local'. This is almost certainly a mistake\n%s" $(tput setaf 226) $(tput sgr0)
    printf "Use ^C to abort and reinvoke with \"DEST_DIR=/usr/local\". Otherwise, press enter to continue. \n ";
    read FU
  fi
fi

#----------------------------------------
# Install package dependecies
#----------------------------------------
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
  	${ECHO} ">>> Installing packages for GNUstep GUI (AppKit) build"
	sudo apt-get install -q -y ${GNUSTEP_GUI_DEPS}
elif [ $IS_FREEBSD ]; then
  pkg install -y cairo
fi

#----------------------------------------
# Download
#----------------------------------------
GIT_PKG_NAME=libs-gui-gui-${gnustep_gui_version}
SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep

if [ ! -d ${BUILD_ROOT}/${GIT_PKG_NAME} ]; then
	curl -L https://github.com/gnustep/libs-gui/archive/gui-${gnustep_gui_version}.tar.gz -o ${BUILD_ROOT}/${GIT_PKG_NAME}.tar.gz
	cd ${BUILD_ROOT}
	tar zxf ${GIT_PKG_NAME}.tar.gz || exit 1
	# Patches
	cd ${BUILD_ROOT}/${GIT_PKG_NAME}
	patch -p1 < ${SOURCES_DIR}/libs-gui_NSApplication.patch
#	patch -p1 < ${SOURCES_DIR}/libs-gui_GSThemeDrawing.patch
	patch -p1 < ${SOURCES_DIR}/libs-gui_NSPopUpButton.patch
	cd Images
	tar zxf ${SOURCES_DIR}/gnustep-gui-images.tar.gz
fi

#----------------------------------------
# Build
#----------------------------------------
cd ${BUILD_ROOT}/${GIT_PKG_NAME} || exit 1
if [ -d obj ]; then
	$MAKE_CMD clean
fi
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	./configure --disable-icu-config || exit 1
else
	./configure || exit 1
fi

if ! [ $IS_FREEBSD ]; then
  $MAKE_CMD || exit 1
fi

#----------------------------------------
# Install
#----------------------------------------
$INSTALL_CMD

#----------------------------------------
# Install services
#----------------------------------------
if ! [ $IS_FREEBSD ]; then
  $CP_CMD ${SOURCES_DIR}/gpbs.service $DEST_DIR/usr/NextSpace/lib/systemd || exit 1
else
  printf "%s%s%s\n" $(tput setaf 226) "FreeBSD User: gpbs seems to have been removed from this project." $(tput sgr0)
  printf "%s%s%s\n" $(tput setaf 226) "Don't worry. Be happy." $(tput sgr0)
fi

if [ "$DEST_DIR" = "" ] && [ "$GITHUB_ACTIONS" != "true" ]; then
	sudo ldconfig
  if ! [ $IS_FREEBSD ]; then
    sudo systemctl daemon-reload || exit 1
    systemctl status gpbs || sudo systemctl enable /usr/NextSpace/lib/systemd/gpbs.service;
  fi
fi
