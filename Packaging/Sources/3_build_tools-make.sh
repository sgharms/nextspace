#!/bin/sh

. ../environment.sh

#----------------------------------------
# Install package dependecies
#----------------------------------------
ECHO ">>> Installing ${OS_ID} packages for GNUstep Make build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	ECHO "Debian-based Linux distribution: calling 'apt-get install'."
	sudo apt-get install -y ${GNUSTEP_MAKE_DEPS} || exit 1
elif [ ${OS_ID} = "freebsd" ]; then
  IS_FREEBSD="1"
  GNUSTEP_MAKE_PORT_DIR="/usr/ports/devel/gnustep-make"
  $PRIV_CMD pkg install -y ${BUILD_TOOLS} || exit 1
  [ "$NEXTSPACE_HOME" ] || NEXTSPACE_HOME=/usr/local/NextSpace

  [ -d $GNUSTEP_MAKE_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
else
	ECHO "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Core/nextspace-core.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | grep -v libobjc2 | grep -v "libdispatch-devel" | awk -c '{print $1}'`
	sudo yum -y install ${DEPS} || exit 1
fi

#----------------------------------------
# Download
#----------------------------------------
CORE_SOURCES=${PROJECT_DIR}/Core
if ! [ "$IS_FREEBSD" ]; then
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
export PKG_CONFIG_PATH="/usr/NextSpace/lib/pkgconfig"
export CC=clang
export CXX=clang++
export CFLAGS="-F/usr/NextSpace/Frameworks"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"/usr/NextSpace/lib"

cp ${CORE_SOURCES}/nextspace.fsl ${BUILD_ROOT}/tools-make-make-${gnustep_make_version}/FilesystemLayouts/nextspace
./configure \
	--prefix=/ \
	--with-config-file=/Library/Preferences/GNUstep.conf \
	--with-layout=nextspace \
	--enable-native-objc-exceptions \
	--enable-debug-by-default \
	--with-library-combo=ng-gnu-gnu
fi # ! [ "$IS_FREEBSD" ]

if [ "$IS_FREEBSD" ]; then
  cd $GNUSTEP_MAKE_PORT_DIR
  # Custom args. Might be set in /etc/make.conf...or not. Here's what works for
  # me. Permit override with env var
  [ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl GNU_CONFIGURE=yes "

  # Inject the custom .fsl file into the source
  $BSDMAKE_CMD $PORTS_MAKE_ARGS extract
  PORT_SRC_DIR=$(find work/ -name gnustep-make\* -type d)
  cp ${CORE_SOURCES}/nextspace.fsl $PORT_SRC_DIR/FilesystemLayouts/nextspace

  # Build

  CONFIGURE_ARGS="\
    --prefix=/usr/local \
    --with-config-file=/usr/local/Library/Preferences/GNUstep.conf \
    --with-layout=nextspace \
    --enable-native-objc-exceptions \
    --enable-debug-by-default \
    --with-library-combo=ng-gnu-gnu
  "

  CONFIGURE_ENV="GNUSTEP_PREFIX='/usr/local/Library/Preferences/GNUstep.conf' \
    PKG_CONFIG_PATH=${NEXTSPACE_HOME}/lib/pkgconfig \
    CC=clang \
    CXX=clang++ \
    CFLAGS=-F${NEXTSPACE_HOME}/Frameworks \
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${NEXTSPACE_HOME}/lib"

  $BSDMAKE_CMD "${PORTS_MAKE_ARGS} CONFIGURE_ARGS=${CONFIGURE_ARGS} CONFIGURE_ENV=${CONFIGURE_ENV}" install

  exit 0
fi

#----------------------------------------
# Install
#----------------------------------------
$INSTALL_CMD || exit 1
cd ${_PWD}
