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
IS_FREEBSD="1"
GNUSTEP_MAKE_PORT_DIR="/usr/ports/devel/gnustep-make"
$PRIV_CMD pkg install -y ${BUILD_TOOLS} || exit 1
[ "$NEXTSPACE_HOME" ] || NEXTSPACE_HOME=/usr/local/NextSpace

[ -d $GNUSTEP_MAKE_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
BUILD_ROOT="${CURPWD}/BUILD_ROOT"

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
#export RUNTIME_VERSION="gnustep-1.8"
export PKG_CONFIG_PATH="${NEXTSPACE_HOME}/lib/pkgconfig"
export CC=clang
export CXX=clang++
export CFLAGS="-F${NEXTSPACE_HOME}/Frameworks -g -O0"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"${NEXTSPACE_HOME}/lib"

cp ${CORE_SOURCES}/nextspace-freebsd.fsl ${BUILD_ROOT}/tools-make-make-${gnustep_make_version}/FilesystemLayouts/nextspace
./configure \
--prefix=/ \
--with-config-file=/Library/Preferences/GNUstep.conf \
--with-layout=nextspace \
--enable-native-objc-exceptions \
--enable-debug-by-default \
--with-library-combo=ng-gnu-gnu

pwd
cp -f ../../patches/pkg-plist $GNUSTEP_MAKE_PORT_DIR
cd $GNUSTEP_MAKE_PORT_DIR
# Custom args. Might be set in /etc/make.conf...or not. Here's what works for
# me. Permit override with env var
[ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl GNU_CONFIGURE=yes "

# Inject the custom .fsl file into the source
$BSDMAKE_CMD $PORTS_MAKE_ARGS extract

LAYOUTS_DIR=$(find $GNUSTEP_MAKE_PORT_DIR -name FilesystemLayouts -type d)
PORT_SRC_DIR=$(dirname $LAYOUTS_DIR)
cp ${CORE_SOURCES}/nextspace-freebsd.fsl $LAYOUTS_DIR/nextspace || exit 1
[ -f "$LAYOUTS_DIR/nextspace" ] || exit 1

# Due to the heavy FSL customizations, trim the post-install hook that we can't make happy.
sed -i.orig '/post-install:/,/^$/d' Makefile

CONFIGURE_ARGS="\
  --with-config-file=/usr/local/Library/Preferences/GNUstep.conf \
  --with-layout=nextspace \
  --enable-native-objc-exceptions \
  --enable-debug-by-default \
  --with-library-combo=ng-gnu-gnu"

CONFIGURE_ENV="PKG_CONFIG_PATH=${NEXTSPACE_HOME}/lib/pkgconfig \
  CC=clang \
  CXX=clang++ \
  CFLAGS='${CFLAGS}'"

# Since we're building with ports, subsequent updates to this component may need a pkg-plist generated
# since we're not using default GNUstep filesystem layout. Here's how I made this:
# ! [ -f pkg-plist.orig ] && cp pkg-plist pkg-plist.orig
# make makeplist |tail -n+2 > pkg-plist

MESSAGES=yes WITH_DEBUG=1 $BSDMAKE_CMD ${PORTS_MAKE_ARGS} CONFIGURE_ARGS="${CONFIGURE_ARGS}" CONFIGURE_ENV="${CONFIGURE_ENV}" build



MESSAGES=yes WITH_DEBUG=1 $BSDMAKE_CMD ${PORTS_MAKE_ARGS} CONFIGURE_ARGS="${CONFIGURE_ARGS}" CONFIGURE_ENV="${CONFIGURE_ENV}" install
