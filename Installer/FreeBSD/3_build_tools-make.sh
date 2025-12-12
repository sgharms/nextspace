#!/bin/sh

CURPWD=${PWD}
BUILD_ROOT="${CURPWD}/BUILD_ROOT"
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

#----------------------------------------
# Install package dependencies
#----------------------------------------
ECHO ">>> Installing ${OS_ID} packages for GNUstep Make build"
$PRIV_CMD pkg install -y ${BUILD_TOOLS} || exit 1
[ "$NEXTSPACE_HOME" ] || NEXTSPACE_HOME=/usr/local/NextSpace

#----------------------------------------
# Download
#----------------------------------------
CORE_SOURCES=${PROJECT_DIR}/Core
GIT_PKG_NAME=tools-make-make-${gnustep_make_version}

if [ ! -d ${BUILD_ROOT}/${GIT_PKG_NAME} ]; then
  curl -L https://github.com/gnustep/tools-make/archive/make-${gnustep_make_version}.tar.gz -o ${BUILD_ROOT}/${GIT_PKG_NAME}.tar.gz
  cd ${BUILD_ROOT}
  tar zxf ${GIT_PKG_NAME}.tar.gz || exit 1
  cd ..
fi

#----------------------------------------
# Build
#----------------------------------------
cd ${BUILD_ROOT}/${GIT_PKG_NAME}
$MAKE_CMD clean
#export RUNTIME_VERSION="gnustep-1.8"
export PKG_CONFIG_PATH="${NEXTSPACE_HOME}/lib/pkgconfig"
export CC=clang
export CXX=clang++
export CFLAGS="-F${NEXTSPACE_HOME}/Frameworks -g -O0"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"${NEXTSPACE_HOME}/lib"

cp ${CORE_SOURCES}/nextspace-freebsd.fsl ${BUILD_ROOT}/tools-make-make-${gnustep_make_version}/FilesystemLayouts/nextspace
./configure \
	--with-config-file=/usr/local/NextSpace/Library/Preferences/GNUstep.conf \
	--with-layout=nextspace \
	--enable-native-objc-exceptions \
	--enable-debug-by-default \
	--with-library-combo=ng-gnu-gnu

#----------------------------------------
# Install
#----------------------------------------
$PRIV_CMD gmake install || exit 1
cd ${CURPWD}
