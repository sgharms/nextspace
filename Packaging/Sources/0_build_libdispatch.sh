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
  ${PRIV_CMD} pkg install ${BUILD_TOOLS} ${RUNTIME_DEPS}
  if ! [ "$DEST_DIR" = "/usr/local" ]; then
    printf "%sYou are on FreeBSD and don't have DEST_DIR set to '/usr/local'. This is almost certainly a mistake.\n%s" $(tput setaf 226) $(tput sgr0)
    printf "%sUse ^C to abort and reinvoke with \"DEST_DIR=/usr/local\". Otherwise, press enter to continue.\n%s" $(tput setaf 226) $(tput sgr0)
    read FU
  fi
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
  if [ $IS_FREEBSD ]; then
    echo "Applying FreeBSD-specific patches"
    cd ${GIT_PKG_NAME}
    if [ -z "${LIBDISPATCH_PATCHES_DIR}" ]; then
      LIBDISPATCH_PATCHES_DIR="/usr/ports/lang/swift$(echo $libdispatch_version | tr -d '.')/files"
    fi
    _LIBDISPATCH_PATCHES=$(echo $LIBDISPATCH_PATCHES | sed 's/\n/\ /g')
    for patchfile in $_LIBDISPATCH_PATCHES; do
      fp="$LIBDISPATCH_PATCHES_DIR/$patchfile"
      echo "Applying ${fp}"
      patch -p1 < $fp
    done
  fi
	cd ..
fi

#----------------------------------------
# Build
#----------------------------------------
cd ${BUILD_ROOT}/${GIT_PKG_NAME} || exit 1
rm -rf _build 2>/dev/null
mkdir -p _build
cd _build

if ! [ $IS_FREEBSD ]; then
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
else
  NEXTSPACE_ROOT="${DEST_DIR}/NextSpace"
  JOBS_VALUE=$(( $(sysctl -n kern.smp.cores)*$(sysctl -n kern.smp.threads_per_core) ))
	$CMAKE_CMD .. \
		-G Ninja \
    -DCMAKE_C_COMPILER=${C_COMPILER} \
    -DCMAKE_CXX_COMPILER=${CXX_COMPILER} \
    -DCMAKE_C_FLAGS=${C_FLAGS} \
    -DCMAKE_CXX_FLAGS=${C_FLAGS} \
    -DCMAKE_INSTALL_PREFIX=${NEXTSPACE_ROOT} \
    -DCMAKE_INSTALL_LIBDIR=${NEXTSPACE_ROOT}/lib \
    -DCMAKE_INSTALL_MANDIR=${NEXTSPACE_ROOT}/Documentation/man \
    -DBUILD_TESTING=OFF \
    -DCMAKE_SKIP_RPATH=ON \
    -DCMAKE_BUILD_TYPE=Debug \
		|| exit 1

  # Not provided as a target
  # $MAKE_CMD clean
	ninja -j ${JOBS_VALUE:-1}
fi

#----------------------------------------
# Install
#----------------------------------------
if [ -z "$IS_FREEBSD" ]; then
	$PRIV_CMD $INSTALL_CMD
else
	${PRIV_CMD} ninja -j ${JOBS_VALUE:-1} install
fi

#----------------------------------------
# Postinstall
#----------------------------------------
if [ -f $NEXTSPACE_ROOT/include/Block_private.h ]; then
  $RM_CMD $NEXTSPACE_ROOT/include/Block_private.h
fi

SHORT_VER=`echo ${libdispatch_version} | awk -F. '{print $1}'`

if [ "$IS_FREEBSD" ]; then
  cd ${NEXTSPACE_ROOT}/lib
else
  cd ${DEST_DIR}/usr/NextSpace/lib
fi


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
