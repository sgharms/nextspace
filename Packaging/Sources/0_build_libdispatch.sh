#!/bin/sh

. ../environment.sh

#----------------------------------------
# Install package dependencies
#----------------------------------------
ECHO ">>> Installing ${OS_ID} packages for Grand Central Dispatch build"
if [ "${OS_ID}" = "debian" ] || [ "${OS_ID}" = "ubuntu" ]; then
	ECHO "Debian-based Linux distribution: calling 'apt-get install'."
	sudo apt-get install -q -y ${BUILD_TOOLS} ${RUNTIME_DEPS} || exit 1
elif [ "${OS_ID}" = "freebsd" ]; then
  LIBDISPATCH_PORT_DIR="/usr/ports/devel/libdispatch"
  $PRIV_CMD pkg install -y ${BUILD_TOOLS} || exit 1
  [ "$NEXTSPACE_HOME" ] || NEXTSPACE_HOME=/usr/local/NextSpace
  [ -d $LIBDISPATCH_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
else
	if [ "${OS_ID}" = "fedora" ] || [ "$OS_ID" = "ultramarine" ]; then
		ECHO "No need to build - installing 'libdispatch-devel' from Fedora repository..."
		sudo dnf -y install libdispatch-devel || exit 1
		exit 0
	fi
	ECHO "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Libraries/libdispatch/libdispatch.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | awk -c '{print $1}'`
	sudo yum -y install ${DEPS} || exit 1
fi

#----------------------------------------
# Download
#----------------------------------------
GIT_PKG_NAME=swift-corelibs-libdispatch-swift-${libdispatch_version}-RELEASE

if [ ! -d ${BUILD_ROOT}/${GIT_PKG_NAME} ] && [ "${OS_ID}" != "freebsd" ]; then
	curl -L https://github.com/apple/swift-corelibs-libdispatch/archive/swift-${libdispatch_version}-RELEASE.tar.gz -o ${BUILD_ROOT}/${GIT_PKG_NAME}.tar.gz
	cd ${BUILD_ROOT}
	tar zxf ${GIT_PKG_NAME}.tar.gz
	cd ..
fi

#----------------------------------------
# Build
#----------------------------------------
if [ "${OS_ID}" != "freebsd" ]; then
  cd ${BUILD_ROOT}/${GIT_PKG_NAME} || exit 1
  rm -rf _build 2>/dev/null
  mkdir -p _build
  cd _build
fi

if [ "${OS_ID}" != "freebsd" ]; then
  $MAKE_CMD clean
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
  $MAKE_CMD

  #----------------------------------------
  # Install
  #----------------------------------------
  #sudo $MAKE_CMD install
  $INSTALL_CMD
else
  cd $LIBDISPATCH_PORT_DIR
  $BSDMAKE_CMD clean
  C_FLAGS="-Wno-error=unused-but-set-variable"
  _CMAKE_COMPILER_ARGS="-DCMAKE_C_COMPILER=${C_COMPILER} \
    -DCMAKE_CXX_COMPILER=${CXX_COMPILER} \
    -DCMAKE_C_FLAGS=${C_FLAGS} \
    -DCMAKE_CXX_FLAGS=${C_FLAGS}"
  _CMAKE_INSTALL_ARGS="-DCMAKE_INSTALL_PREFIX=${NEXTSPACE_HOME}\
    -DCMAKE_INSTALL_LIBDIR=${NEXTSPACE_HOME}/lib\
    -DCMAKE_INSTALL_MANDIR=${NEXTSPACE_HOME}/Documentation/man"
  CMAKE_ARGS="${_CMAKE_COMPILER_ARGS} ${_CMAKE_INSTALL_ARGS}"

  cd $LIBDISPATCH_PORT_DIR
  $BSDMAKE_CMD CMAKE_ARGS="${CMAKE_ARGS}" \
    CMAKE_ON="INSTALL_PRIVATE_HEADERS MAKE_SKIP_RPATH" \
    CMAKE_OFF="BUILD_TESTING" \
    CMAKE_BUILD_TYPE="Debug" \
    USES="cmake:noninja,testing compiler:c++17-lang"

  $BSDMAKE_CMD install PREFIX=$NEXTSPACE_HOME
fi

#----------------------------------------
# Postinstall
#----------------------------------------
cd ${DEST_DIR}/usr/NextSpace/ > /dev/null 2>&1  || cd $NEXTSPACE_HOME
SHORT_VER=`echo ${libdispatch_version} | awk -F. '{print $1}'`

$RM_CMD -f include/Block_private.h

cd lib

ECHO "Installing symlinks for libBlocksRuntime..."
if [ -f libBlocksRuntime.so ]; then
  ECHO "-- Creating link for libBlocksRuntime.so.${libdispatch_version}"
  $MV_CMD libBlocksRuntime.so libBlocksRuntime.so.${libdispatch_version}
  $LN_CMD libBlocksRuntime.so.${libdispatch_version} libBlocksRuntime.so.${SHORT_VER}
  $LN_CMD libBlocksRuntime.so.${libdispatch_version} libBlocksRuntime.so
elif [ ${OS_ID} = "freebsd" ]; then
  ECHO "FreeBSD detected. Coherence between kernel and userland means this step can be skipped."
else
  ECHO "...libBlocksRunTime.so not found. Skipping"
fi

ECHO "Installing symlinks for libdispatch..."
if [ -f libdispatch.so ]; then
  ECHO "-- Creating link for libdispatch.so.${libdispatch_version}"
  $MV_CMD libdispatch.so libdispatch.so.${libdispatch_version}
  $LN_CMD libdispatch.so.${libdispatch_version} libdispatch.so.${SHORT_VER}
  $LN_CMD libdispatch.so.${libdispatch_version} libdispatch.so
else
  ECHO "...libdispatch.so not found. Skipping"
fi

if [ "$DEST_DIR" = "" ]; then
	$PRIV_CMD ldconfig
fi
