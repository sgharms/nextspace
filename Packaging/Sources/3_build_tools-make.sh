#!/bin/sh

. ../environment.sh

#----------------------------------------
# Install package dependecies
#----------------------------------------
${ECHO} ">>> Installing ${OS_ID} packages for GNUstep Make build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	${ECHO} "Debian-based Linux distribution: calling 'apt-get install'."
	sudo apt-get install -y ${GNUSTEP_MAKE_DEPS} || exit 1
elif [ $IS_FREEBSD ]; then
  # Nothing needs to happen here...
else
	${ECHO} "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Core/nextspace-core.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | grep -v libobjc2 | grep -v "libdispatch-devel" | awk -c '{print $1}'`
	sudo yum -y install ${DEPS} || exit 1
fi

#----------------------------------------
# Download
#----------------------------------------
GIT_PKG_NAME=tools-make-make-${gnustep_make_version}
CORE_SOURCES=${PROJECT_DIR}/Core

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
export CC=clang
export CXX=clang++

if ! [ $IS_FREEBSD ]; then
  $MAKE_CMD clean
  export PKG_CONFIG_PATH="/usr/NextSpace/lib/pkgconfig"
  export CFLAGS="-F/usr/NextSpace/Frameworks"
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"/usr/NextSpace/lib"

  cp ${CORE_SOURCES}/nextspace.fsl ${BUILD_ROOT}/tools-make-make-${gnustep_make_version}/FilesystemLayouts/nextspace
else
  if ! [ "$NEXTSPACE_ROOT" = "/usr/local/NextSpace" ]; then
    printf "%sYou are on FreeBSD and don't have NEXTSPACE_ROOT set to '/usr/local/NextSpace'. This is almost certainly a mistake.\n%s" $(tput setaf 226) $(tput sgr0)
    printf "%sUse ^C to abort and reinvoke with \"NEXTSPACE_ROOT=/usr/local/NextSpace\". Otherwise, press enter to continue.\n%s" $(tput setaf 226) $(tput sgr0)
    read FU
  fi
  export PKG_CONFIG_PATH="$NEXTSPACE_ROOT/lib/pkgconfig"
  export CFLAGS="-F$NEXTSPACE_ROOT/Frameworks"
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$NEXTSPACE_ROOT/lib"

  cp ${CORE_SOURCES}/nextspace-freebsd.fsl ${BUILD_ROOT}/tools-make-make-${gnustep_make_version}/FilesystemLayouts/nextspace
fi

CONFIG_FILE_PATH="$DEST_DIR/Library/Preferences/GNUstep.conf"

./configure \
	--prefix=/ \
	--with-config-file=$CONFIG_FILE_PATH \
	--with-layout=nextspace \
	--enable-native-objc-exceptions \
	--enable-debug-by-default \
	--with-library-combo=ng-gnu-gnu

#----------------------------------------
# Install
#----------------------------------------
$INSTALL_CMD || exit 1
cd ${_PWD}
