#!/bin/sh

. ../environment.sh

if [ ${OS_ID} != "freebsd" ]; then
  . /etc/profile.d/nextspace.sh
else
  IS_FREEBSD="/usr/local"
  . ${IS_FREEBSD}/etc/profile.d/nextspace.sh
fi

#----------------------------------------
# Install package dependencies
#----------------------------------------
ECHO ">>> Installing ${OS_ID} packages for WRaster library build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	ECHO "Debian-based Linux distribution: calling 'apt-get install'."
	$PRIV_CMD apt-get install -y ${WRASTER_DEPS} || exit 1
  . /Developer/Makefiles/GNUstep.sh
elif [ "$IS_FREEBSD" ]; then
  ECHO ">>> Installing ${OS_ID} packages for WRaster library build"
  . "$($GNUSTEP_CONFIG_CMD --variable=GNUSTEP_MAKEFILES)/GNUstep.sh"
	$PRIV_CMD pkg install -y ${WRASTER_DEPS} || exit 1
else
	ECHO "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Libraries/libwraster/libwraster.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | grep -v nextspace-core-devel | awk -c '{print $1}'`
	$PRIV_CMD yum -y install ${DEPS} || exit 1
  . /Developer/Makefiles/GNUstep.sh
fi

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
cd ${BUILD_DIR}
export CC=${C_COMPILER}
export CMAKE=${CMAKE_CMD}
export QA_SKIP_BUILD_ROOT=1
export CFLAGS="${CFLAGS} -Wno-unused-function"

if [ "$IS_FREEBSD" ]; then
fi

$MAKE_CMD || exit 1
$INSTALL_CMD || exit 1

if [ "$DEST_DIR" = "" ]; then
	$PRIV_CMD ldconfig
fi
