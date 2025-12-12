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
ECHO ">>> Installing ${OS_ID} packages for NextSpace frameworks build"
. /usr/local/Developer/Makefiles/GNUstep.sh

#----------------------------------------
# Download
#----------------------------------------
SOURCES_DIR=${PROJECT_DIR}/Frameworks
BUILD_DIR=${BUILD_ROOT}/Frameworks

if [ -d ${BUILD_DIR} ]; then
	rm -rf ${BUILD_DIR}
fi
cp -R ${SOURCES_DIR} ${BUILD_ROOT}

#----------------------------------------
# Build
#----------------------------------------
cd ${BUILD_DIR}

$MAKE_CMD clean
$MAKE_CMD -j${CPU_COUNT} || exit 1

#----------------------------------------
# Install
#----------------------------------------
$MAKE_CMD install GNUSTEP_INSTALLATION_DOMAIN=SYSTEM

$PRIV_CMD ldconfig -R

#----------------------------------------
# Install standard images to skel
#----------------------------------------
ECHO ">>> Installing NX standard images to /usr/local/etc/skel/Library/Images"
$PRIV_CMD mkdir -p /usr/local/etc/skel/Library/Images
$PRIV_CMD cp ${NEXTSPACE_HOME}/Frameworks/DesktopKit.framework/Versions/Current/Resources/Images/NX*.tiff /usr/local/etc/skel/Library/Images/
