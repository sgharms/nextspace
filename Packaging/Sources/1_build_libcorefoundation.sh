#!/bin/sh

. ../environment.sh

#----------------------------------------
# Install package dependecies
#----------------------------------------
ECHO ">>> Installing ${OS_ID} packages for CoreFoundation library build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	ECHO "Debian-based Linux distribution: calling 'apt-get install'."
	$PRIV_CMD apt-get install -y ${RUNTIME_DEPS} || exit 1
elif [ "${OS_ID}" = "freebsd" ]; then
  FOUNDATION_BEARING_PORT_DIR="/usr/ports/lang/swift510"
  $PRIV_CMD pkg install -y ${BUILD_TOOLS} ${RUNTIME_DEPS} || exit 1
  [ "$NEXTSPACE_HOME" ] || NEXTSPACE_HOME=/usr/local/NextSpace
  [ -d $FOUNDATION_BEARING_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
else
	ECHO ">>> Installing ${OS_ID} packages for CoreFoundation build"
	ECHO "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Libraries/libcorefoundation/libcorefoundation.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | awk -c '{print $1}'`
	$PRIV_CMD yum -y install ${DEPS} git || exit 1
fi

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

if [ ${OS_ID} = "freebsd" ]; then
  # For applying patches
  FREEBSD_PATCHES_PARENT_DIR=${PWD}

  # Prepare the port we're going to excise Foundation from
  cd $FOUNDATION_BEARING_PORT_DIR
  $BSDMAKE_CMD patch || exit 1

  # Find the patched sub-tree and copy it to a place where we can hybridize
  PATCHED_CF_DIR=$(find work -type d -name CoreFoundation | head -1)
  TEMP_DIR="${TMPDIR:-/tmp}/corefoundation-hybrid" # (-theory). Pour one out for Chester Bennington
  rm -rf $TEMP_DIR && mkdir -p $TEMP_DIR || exit 1
  cp -a "${PATCHED_CF_DIR}" $TEMP_DIR

  # Generate patches from trunkmaster's edits
  cd "${BUILD_ROOT}/${CF_PKG_NAME}"
  # The SHA is where trunkmaster started stacking changes on main
  TRUNKMASTER_PATCHES_DIR="/tmp/cf-friend-patches.$$"
  TRUNKMASTER_FORK_SHA="dbca8c7ddcfd19f7f6f6e1b60fd3ee3f748e263c"
  rm -rf ${TRUNKMASTER_PATCHES_DIR}
  git format-patch -o ${TRUNKMASTER_PATCHES_DIR} ${TRUNKMASTER_FORK_SHA}..@

  # Test patches
  cd $TEMP_DIR
  git init .
  git add .
  git commit -m 'Initial commit: Swift-extracted CoreFoundation'

  # Apply the TM patches and ignore non-zero exit status (see below)
  git apply --reject -p1 ${TRUNKMASTER_PATCHES_DIR}/* || true

  # Remove rejections. The swift510 port integrated these changes and
  # thus they are inapplicable.
  find . -name \*.rej -exec rm {} \;

  # Commit up. Even if it's ephemeral, it's useful for debugging
  git add .
  git commit -am 'Patch reconciliation complete'

  # Apply custom FreeBSD patches
  ECHO "Apply FreeBSD patch"
  CF_PATCH_PATH="${FREEBSD_PATCHES_PARENT_DIR}/freebsd_patches/0001-CoreFoundation_RunLoop.subproj_CFFileDescriptor.h.patch"
  git apply ${CF_PATCH_PATH}

  $MV_CMD "${BUILD_ROOT}/${CF_PKG_NAME}" "${BUILD_ROOT}/${CF_PKG_NAME}-orig"
  $MKDIR_CMD "${BUILD_ROOT}/${CF_PKG_NAME}"
  cp -r CoreFoundation/* "${BUILD_ROOT}/${CF_PKG_NAME}"
fi

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
if [ ${OS_ID} = "freebsd" ]; then
  $PRIV_CMD $BSDMAKE_CMD install
else
  $INSTALL_CMD
fi

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

if [ "$DEST_DIR" = "" ]; then
	$PRIV_CMD ldconfig
fi
