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
$MAKE_CMD || exit 1

#----------------------------------------
# Install
#----------------------------------------
$INSTALL_CMD

$PRIV_CMD ldconfig -R
