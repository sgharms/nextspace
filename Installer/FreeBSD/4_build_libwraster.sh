#!/bin/sh
# WRaster is the WindowMaker WM raster image library

CURPWD=${PWD}
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

. /usr/local/etc/profile.d/nextspace.sh

#----------------------------------------
# Install package dependencies
#----------------------------------------

ECHO ">>> Installing ${OS_ID} packages for WRaster library build"
pkg install -y ${WRASTER_DEPS} || exit 1

#----------------------------------------
# Download
#----------------------------------------
SOURCES_DIR=${PROJECT_DIR}/Libraries/libwraster
BUILD_DIR=${BUILD_ROOT}/libwraster

if [ -d ${BUILD_DIR} ]; then
	rm -rf ${BUILD_DIR}
fi
cp -R ${SOURCES_DIR} ${BUILD_ROOT}

#----------------------------------------
# Build
#----------------------------------------
. /usr/local/Developer/Makefiles/GNUstep.sh

cd ${BUILD_DIR}
export PREFIX=/usr/local
export CC=${C_COMPILER}
export CMAKE=${CMAKE_CMD}
export QA_SKIP_BUILD_ROOT=1
export CMAKE_INCLUDE_PATH=/usr/local/include

$MAKE_CMD messages=yes debug=yes || exit 1
$INSTALL_CMD || exit 1

if [ "$DEST_DIR" = "" ]; then
  $PRIV_CMD ldconfig -R
fi
