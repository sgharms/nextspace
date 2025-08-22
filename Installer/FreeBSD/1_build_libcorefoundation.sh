#!/bin/sh

CURPWD=${PWD}
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

#----------------------------------------
# Install package dependencies
#----------------------------------------

IS_FREEBSD=1
FOUNDATION_BEARING_PORT_DIR="/usr/ports/lang/swift510"
$PRIV_CMD pkg install -y ${BUILD_TOOLS} ${RUNTIME_DEPS} || exit 1
[ "$NEXTSPACE_HOME" ] || NEXTSPACE_HOME=/usr/local/NextSpace
[ -d $FOUNDATION_BEARING_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)

#----------------------------------------
# Download
#----------------------------------------
CF_PKG_NAME=apple-corefoundation-${libcorefoundation_version}

if [ ! -d ${BUILD_ROOT}/${CF_PKG_NAME} ]; then
  CUSTOM_CF_GH_REPO="https://github.com/trunkmaster/apple-corefoundation"
  if [ ${OS_ID} = "freebsd" ]; then
    # FreeBSD needs the full history so that we can build a patchset from
    # dbca8c7ddcfd19f7f6f6e1b60fd3ee3f748e263c, where trunkmaster made
    # custom edits
    git clone           ${CUSTOM_CF_GH_REPO} ${BUILD_ROOT}/${CF_PKG_NAME}
  else
    git clone --depth 1 ${CUSTOM_CF_GH_REPO} ${BUILD_ROOT}/${CF_PKG_NAME}
  fi
fi

if [ ! -d ${BUILD_ROOT}/${CF_PKG_NAME} ]; then
  echo "Surprisingly, ${BUILD_ROOT}/${CF_PKG_NAME} was not created when it was guaranteed to."
  read DERP
fi

# For applying patches
FREEBSD_PATCHES_PARENT_DIR=${PWD}

# Prepare the port we're going to excise Foundation from
cd $FOUNDATION_BEARING_PORT_DIR
$BSDMAKE_CMD patch || exit 1

PATCHED_LIBDISPATCH_DIR=$(find work -type d -name swift-corelibs-libdispatch | head -1)
cd $PATCHED_LIBDISPATCH_DIR
rm -rf .build 2>/dev/null
mkdir -p .build
cd .build
C_FLAGS="-I${NEXTSPACE_HOME}/include -Wno-switch -Wno-enum-conversion"
$CMAKE_CMD .. \
  -DCMAKE_C_COMPILER=${C_COMPILER} \
  -DCMAKE_C_FLAGS="${C_FLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="-L${NEXTSPACE_HOME}/lib -L/usr/local/lib -luuid" \
  -DBUILD_SHARED_LIBS=YES \
  -DCMAKE_INSTALL_PREFIX=${NEXTSPACE_HOME} \
  -DCMAKE_INSTALL_LIBDIR=${NEXTSPACE_HOME}/lib \
  -DCMAKE_LIBRARY_PATH=${NEXTSPACE_HOME}/lib \
  \
  -DCMAKE_SKIP_RPATH=ON \
  -DCMAKE_BUILD_TYPE=Debug \
  || exit 1

$MAKE_CMD || exit 1
$PRIV_CMD $BSDMAKE_CMD install || exit 1

# Find the ports(7)-patched sub-tree and copy it to a place where we can
# hybridize
cd $FOUNDATION_BEARING_PORT_DIR
PATCHED_CF_DIR=$(find work -type d -name CoreFoundation | head -1)
TEMP_DIR="${TMPDIR:-/tmp}/corefoundation-hybrid" # (-theory). Pour one out for Chester Bennington
rm -rf $TEMP_DIR && mkdir -p $TEMP_DIR || exit 1
cp -a "${PATCHED_CF_DIR}" $TEMP_DIR

# Generate patches from trunkmaster's edits
cd "${BUILD_ROOT}/${CF_PKG_NAME}"
TRUNKMASTER_PATCHES_DIR="/tmp/cf-friend-patches.$$"
# The SHA is where trunkmaster started stacking changes on main
TRUNKMASTER_FORK_SHA="dbca8c7ddcfd19f7f6f6e1b60fd3ee3f748e263c"
ECHO "Writing patches to ${TRUNKMASTER_PATCHES_DIR} from ${PWD}"
git format-patch -o ${TRUNKMASTER_PATCHES_DIR} ${TRUNKMASTER_FORK_SHA}..HEAD

# This patch does not apply cleanly as it appears to have been already
# applied
rm ${TRUNKMASTER_PATCHES_DIR}/0002-Added-implementation-of-CFFileDescriptor.patch

# Test patches
cd $TEMP_DIR
GIT_PREFIX="-c user.name=\"$(id -un)\" -c user.email=\"$(id -un)@localhost.domain\""
git $GIT_PREFIX init .
git $GIT_PREFIX add .
git $GIT_PREFIX commit -m 'Initial commit: Swift-extracted CoreFoundation'

# Apply the TM patches and ignore non-zero exit status (see below)
git $GIT_PREFIX apply --reject -p1 ${TRUNKMASTER_PATCHES_DIR}/* || true

# Commit up. Even if it's ephemeral, it's useful for debugging
# Apply custom FreeBSD patches
ECHO "Apply FreeBSD patch"
CF_PATCH_PATH="${FREEBSD_PATCHES_PARENT_DIR}/patches/0001-CoreFoundation_RunLoop.subproj_CFFileDescriptor.h.patch"
git apply ${CF_PATCH_PATH}
git $GIT_PREFIX add .
git $GIT_PREFIX commit -am 'trunkmaster/FreeBSD Patch reconciliation complete'

$MV_CMD -f "${BUILD_ROOT}/${CF_PKG_NAME}" "${BUILD_ROOT}/${CF_PKG_NAME}-orig"
$MKDIR_CMD "${BUILD_ROOT}/${CF_PKG_NAME}"
cp -r CoreFoundation/* "${BUILD_ROOT}/${CF_PKG_NAME}"

#----------------------------------------
# Build
#----------------------------------------
# CoreFoundation
cd ${BUILD_ROOT}/${CF_PKG_NAME} || exit 1
rm -rf .build 2>/dev/null
mkdir -p .build
cd .build
C_FLAGS="-I${NEXTSPACE_HOME}/include -Wno-switch -Wno-enum-conversion"
$CMAKE_CMD .. \
	-DCMAKE_C_COMPILER=${C_COMPILER} \
	-DCMAKE_C_FLAGS="${C_FLAGS}" \
	-DCMAKE_SHARED_LINKER_FLAGS="-L${NEXTSPACE_HOME}/lib -L/usr/local/lib -luuid" \
	-DCF_DEPLOYMENT_SWIFT=NO \
	-DBUILD_SHARED_LIBS=YES \
	-DCMAKE_INSTALL_PREFIX=${NEXTSPACE_HOME} \
	-DCMAKE_INSTALL_LIBDIR=${NEXTSPACE_HOME}/lib \
	-DCMAKE_LIBRARY_PATH=${NEXTSPACE_HOME}/lib \
	\
	-DCMAKE_SKIP_RPATH=ON \
	-DCMAKE_BUILD_TYPE=Debug \
	|| exit 1

$MAKE_CMD || exit 1

#----------------------------------------
# Install
#----------------------------------------

### CoreFoundation
cd ${BUILD_ROOT}/${CF_PKG_NAME}/.build || exit 1
$PRIV_CMD $BSDMAKE_CMD install

CF_DIR=${NEXTSPACE_HOME}/Frameworks/CoreFoundation.framework

$MKDIR_CMD ${CF_DIR}/Versions/${libcorefoundation_version}
cd $CF_DIR
# Headers
$MV_CMD Headers Versions/${libcorefoundation_version}
$LN_CMD Versions/Current/Headers Headers
cd Versions
$LN_CMD ${libcorefoundation_version} Current
cd ..
# Libraries
$MV_CMD libCoreFoundation.so* Versions/${libcorefoundation_version}
$LN_CMD Versions/Current/libCoreFoundation.so.${libcorefoundation_version} libCoreFoundation.so
$LN_CMD Versions/Current/libCoreFoundation.so.${libcorefoundation_version} CoreFoundation
cd ../../lib
$RM_CMD libCoreFoundation.so*
$LN_CMD ../Frameworks/CoreFoundation.framework/Versions/${libcorefoundation_version}/libCoreFoundation.so* ./

$PRIV_CMD echo "/usr/local/NextSpace/lib" >> /usr/local/libdata/ldconfig/nextspace
$PRIV_CMD service ldconfig restart

if [ "$DEST_DIR" = "" ]; then
  $PRIV_CMD ldconfig -R
fi
