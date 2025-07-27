#!/bin/sh

. ../environment.sh

#----------------------------------------
# Install package dependencies
#----------------------------------------
echo ">>> Installing ${OS_ID} packages for Grand Central Dispatch build"
if [ "${OS_ID}" = "debian" ] || [ "${OS_ID}" = "ubuntu" ]; then
	${ECHO} "Debian-based Linux distribution: calling 'apt-get install'."
	sudo apt-get install -q -y ${BUILD_TOOLS} ${RUNTIME_DEPS} || exit 1
elif [ "${OS_ID}" = "freebsd" ]; then
  ${PRIV_CMD} pkg install ${BUILD_TOOLS}
else
	if [ "${OS_ID}" = "fedora" ] || [ "$OS_ID" = "ultramarine" ]; then
		${ECHO} "No need to build - installing 'libdispatch-devel' from Fedora repository..."
		sudo dnf -y install libdispatch-devel || exit 1
		exit 0
	fi
	${ECHO} "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Libraries/libdispatch/libdispatch.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | awk -c '{print $1}'`
	sudo yum -y install ${DEPS} || exit 1
fi

#----------------------------------------
# Download
#----------------------------------------
GIT_PKG_NAME=swift-corelibs-libdispatch-swift-${libdispatch_version}-RELEASE

if [ ! -d ${BUILD_ROOT}/${GIT_PKG_NAME} ]; then
	curl -L https://github.com/swiftlang/swift-corelibs-libdispatch/archive/refs/tags/swift-${libdispatch_version}-RELEASE.tar.gz -o ${BUILD_ROOT}/${GIT_PKG_NAME}.tar.gz
	cd ${BUILD_ROOT}
	tar zxf ${GIT_PKG_NAME}.tar.gz
	cd ..
fi

#----------------------------------------
# Build
#----------------------------------------
cd ${BUILD_ROOT}/${GIT_PKG_NAME} || exit 1
rm -rf _build 2>/dev/null
mkdir -p _build
cd _build

if [ $IS_FREEBSD ]; then
	$CMAKE_CMD .. \
		-G Ninja \
    -DCMAKE_C_COMPILER=${C_COMPILER} \
    -DCMAKE_CXX_COMPILER=${CXX_COMPILER} \
    -DCMAKE_C_FLAGS=${C_FLAGS} \
    -DCMAKE_CXX_FLAGS=${C_FLAGS} \
    -DCMAKE_INSTALL_PREFIX=/usr/NextSpace \
    -DCMAKE_INSTALL_LIBDIR=/usr/NextSpace/lib \
    -DCMAKE_INSTALL_MANDIR=/usr/NextSpace/Documentation/man \
    -DBUILD_TESTING=OFF \
    -DCMAKE_SKIP_RPATH=ON \
    -DCMAKE_BUILD_TYPE=Debug \
		|| exit 1
	ninja -j8
	${PRIV_CMD} ninja -j8 install
else
  C_FLAGS="-Wno-error=unused-but-set-variable"
  $CMAKE_CMD .. \
    -DCMAKE_C_COMPILER=${C_COMPILER} \
    -DCMAKE_CXX_COMPILER=${CXX_COMPILER} \
    -DCMAKE_C_FLAGS=${C_FLAGS} \
    -DCMAKE_CXX_FLAGS=${C_FLAGS} \
    -DCMAKE_INSTALL_PREFIX=/usr/NextSpace \
    -DCMAKE_INSTALL_LIBDIR=/usr/NextSpace/lib \
    -DCMAKE_INSTALL_MANDIR=/usr/NextSpace/Documentation/man \
    -DINSTALL_PRIVATE_HEADERS=YES \
    -DBUILD_TESTING=OFF \
    \
    -DCMAKE_SKIP_RPATH=ON \
    -DCMAKE_BUILD_TYPE=Debug \
    || exit 1
  #	-DCMAKE_LINKER=/usr/bin/ld.gold \

  $MAKE_CMD clean
  $MAKE_CMD
fi

#----------------------------------------
# Install
#----------------------------------------
#sudo $MAKE_CMD install
if [ -z "$IS_FREEBSD" ]; then
	$INSTALL_CMD
fi

#----------------------------------------
# Postinstall
#----------------------------------------
if [ -z "$IS_FREEBSD" ]; then
	$RM_CMD $DEST_DIR/usr/NextSpace/include/Block_private.h
fi

SHORT_VER=`echo ${libdispatch_version} | awk -F. '{print $1}'`

cd ${DEST_DIR}/usr/NextSpace/lib

$ECHO "-- Creating link for libBlocksRuntime.so.${libdispatch_version}"
$PRIV_CMD $MV_CMD libBlocksRuntime.so libBlocksRuntime.so.${libdispatch_version}
$PRIV_CMD $LN_CMD libBlocksRuntime.so.${libdispatch_version} libBlocksRuntime.so.${SHORT_VER}
$PRIV_CMD $LN_CMD libBlocksRuntime.so.${libdispatch_version} libBlocksRuntime.so

$ECHO "-- Creating link for libdispatch.so.${libdispatch_version}"
$PRIV_CMD $MV_CMD libdispatch.so libdispatch.so.${libdispatch_version}
$PRIV_CMD $LN_CMD libdispatch.so.${libdispatch_version} libdispatch.so.${SHORT_VER}
$PRIV_CMD $LN_CMD libdispatch.so.${libdispatch_version} libdispatch.so

if [ "$DEST_DIR" = "" ]; then
	$PRIV_CMD ldconfig
fi
