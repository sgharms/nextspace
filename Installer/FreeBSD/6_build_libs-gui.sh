#!/bin/sh

CURPWD=${PWD}
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
GNUSTEP_GUI_PORT_DIR="/usr/ports/x11-toolkits/gnustep-gui"
[ -d $GNUSTEP_GUI_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
[ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="GNUSTEP_PREFIX=/usr/local/Developer DEFAULT_VERSIONS+=ssl=openssl"
$PRIV_CMD pkg install -y ${GNUSTEP_GUI_DEPS}

SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep
cd $GNUSTEP_GUI_PORT_DIR # We should already be there but...
$BSDMAKE_CMD $PORTS_MAKE_ARGS patch
PORT_SOURCE_DIR=$(find . -name libs-gui\* -type d)
if [ -z "$PORT_SOURCE_DIR" ]; then
  echo "Oh no! Couldn't find a directory, was ${PORT_SOURCE_DIR}" >&2
  exit 1
fi

cp -Rf $PORT_SOURCE_DIR ${BUILD_ROOT}/$(basename $PORT_SOURCE_DIR)
cd ${BUILD_ROOT}/$(basename $PORT_SOURCE_DIR)

# Patches
echo "Patching ${SOURCES_DIR}/libs-gui_NSApplication.patch"
patch -p1 --forward --batch < ${SOURCES_DIR}/libs-gui_NSApplication.patch

# Disabled upstream
#	patch -p1 < ${SOURCES_DIR}/libs-gui_GSThemeDrawing.patch

echo "${SOURCES_DIR}/libs-gui_NSPopUpButton.patch"
patch -p1 --forward --batch < ${SOURCES_DIR}/libs-gui_NSPopUpButton.patch

echo "${PROJECT_DIR}/Installer/FreeBSD/patches/freebsd"

# This patch doesn't have a leading dir on it, so it's different than the
# previous two
patch -p0 --forward --batch < ${PROJECT_DIR}/Installer/FreeBSD/patches/freebsd

cd Images
tar zxf ${SOURCES_DIR}/gnustep-gui-images.tar.gz

cd ${BUILD_ROOT}/$(basename $PORT_SOURCE_DIR)
./configure --with-default-config=/usr/local/Library/Preferences/GNUstep.conf

$MAKE_CMD -j${CPU_COUNT} install || { echo "Install of gnustep-gui port failed"; exit 1; }

echo "Installed $(basename $PORT_SOURCE_DIR)"
