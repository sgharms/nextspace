#!/bin/sh

. ../environment.sh
. /etc/profile.d/nextspace.sh

#----------------------------------------
# Install package dependencies
#----------------------------------------
${ECHO} ">>> Installing ${OS_ID} packages for WRaster library build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	${ECHO} "Debian-based Linux distribution: calling 'apt-get install'."
	sudo apt-get install -y ${WRASTER_DEPS} || exit 1
elif [ $IS_FREEBSD ]; then
  ${ECHO} FreeBSD detected
  $PRIV_CMD pkg install ${WRASTER_DEPS}
else
	${ECHO} "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Libraries/libwraster/libwraster.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | grep -v nextspace-core-devel | awk -c '{print $1}'`
	sudo yum -y install ${DEPS} || exit 1
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
. /Developer/Makefiles/GNUstep.sh
cd ${BUILD_DIR}
export CC=${C_COMPILER}
export CMAKE=${CMAKE_CMD}
export QA_SKIP_BUILD_ROOT=1

if [ $IS_FREEBSD ]; then
  ${CMAKE_CMD} .. -DCMAKE_C_FLAGS="-I/usr/local/include/GraphicsMagick" \
               -DCMAKE_EXE_LINKER_FLAGS="-L/usr/local/lib" \
               -DCMAKE_SHARED_LINKER_FLAGS="-L/usr/local/lib"
fi

$MAKE_CMD || exit 1
$INSTALL_CMD || exit 1

if [ "$DEST_DIR" = "" ]; then
	$PRIV_CMD ldconfig
fi
