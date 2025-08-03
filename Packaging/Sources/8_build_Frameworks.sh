#!/bin/sh

. ../environment.sh
. "${PROJECT_DIR}/Core/nextspace${IS_FREEBSD:+-freebsd}.fsl"
. "${GNUSTEP_MAKEFILES}/GNUstep.sh"
. ${DEST_DIR}/etc/profile.d/nextspace.sh

#----------------------------------------
# Install package dependecies
#----------------------------------------
${ECHO} ">>> Installing ${OS_ID} packages for NextSpace frameworks build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	${ECHO} "Debian-based Linux distribution: calling 'apt-get install'."
	$PRIV_CMD apt-get install -y ${FRAMEWORKS_BUILD_DEPS}
	$PRIV_CMD apt-get install -y ${FRAMEWORKS_RUN_DEPS}
elif [ $IS_FREEBSD ]; then
	$PRIV_CMD pkg install -y ${FRAMEWORKS_BUILD_DEPS}
else
	${ECHO} "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Frameworks/nextspace-frameworks.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | grep -v "nextspace" | awk -c '{print $1}'`
	$PRIV_CMD yum -y install ${DEPS} || exit 1
	DEPS=`rpmspec -q --requires ${SPEC_FILE} | grep -v corefoundation | grep -v nextspace | awk -c '{print $1}'`
	$PRIV_CMD yum -y install ${DEPS} || exit 1
fi

#----------------------------------------
# Download
#----------------------------------------
SOURCES_DIR=${PROJECT_DIR}/Frameworks
BUILD_DIR=${BUILD_ROOT}/Frameworks

if [ -d ${BUILD_DIR} ]; then
	rm -rf ${BUILD_DIR}
fi
cp -R ${SOURCES_DIR} ${BUILD_ROOT}

#----------------------------------------
# Build
#----------------------------------------
cd ${BUILD_DIR}

$MAKE_CMD clean
$IS_FREEBSD || $MAKE_CMD || exit 1

#----------------------------------------
# Install
#----------------------------------------
$INSTALL_CMD
if [ "$DEST_DIR" = "" ]; then
	$PRIV_CMD ldconfig
	$LN_CMD /usr/NextSpace/Frameworks/DesktopKit.framework/Resources/25-nextspace-fonts.conf /etc/fonts/conf.d/25-nextspace-fonts.conf
fi
