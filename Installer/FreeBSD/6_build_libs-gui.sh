#!/bin/sh

CURPWD=${PWD}
BUILD_ROOT="${CURPWD}/BUILD_ROOT"
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD
BUILD_ROOT="${CURPWD}/BUILD_ROOT"

NEXTSPACE_HOME="/usr/local/NextSpace"
. /usr/local/etc/profile.d/nextspace.sh

#----------------------------------------
# Install package dependencies
#----------------------------------------
ECHO ">>> Installing packages for GNUstep GUI (AppKit) build"
. /usr/local/Developer/Makefiles/GNUstep.sh
$PRIV_CMD pkg install -y ${GNUSTEP_GUI_DEPS}

#----------------------------------------
# Download from upstream GNUstep (not ports)
#----------------------------------------
GIT_PKG_NAME=libs-gui-gui-${gnustep_gui_version}
SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep

if [ ! -d ${BUILD_ROOT}/${GIT_PKG_NAME} ]; then
	ECHO ">>> Downloading GNUstep GUI ${gnustep_gui_version} from GitHub"
	fetch -o ${BUILD_ROOT}/${GIT_PKG_NAME}.tar.gz https://github.com/gnustep/libs-gui/archive/gui-${gnustep_gui_version}.tar.gz || exit 1
	cd ${BUILD_ROOT}
	tar zxf ${GIT_PKG_NAME}.tar.gz || exit 1

	# Patches
	cd ${BUILD_ROOT}/${GIT_PKG_NAME}
	ECHO ">>> Applying patches"
	patch -p1 --forward --batch < ${SOURCES_DIR}/libs-gui_NSApplication.patch
	# Disabled upstream
	#	patch -p1 < ${SOURCES_DIR}/libs-gui_GSThemeDrawing.patch
	patch -p1 --forward --batch < ${SOURCES_DIR}/libs-gui_NSPopUpButton.patch

	cd Images
	tar zxf ${SOURCES_DIR}/gnustep-gui-images.tar.gz
fi

#----------------------------------------
# Build
#----------------------------------------
cd ${BUILD_ROOT}/${GIT_PKG_NAME} || exit 1
ECHO ">>> Configuring GNUstep GUI"
./configure --with-default-config=${NEXTSPACE_HOME}/Library/Preferences/GNUstep.conf || exit 1

ECHO ">>> Building and installing GNUstep GUI"
$MAKE_CMD install debug=yes messages=yes GNUSTEP_INSTALLATION_DOMAIN=SYSTEM -j${CPU_COUNT} || { echo "Install of gnustep-gui failed"; exit 1; }

echo "Installed ${GIT_PKG_NAME}"
