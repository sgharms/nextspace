#!/bin/sh

. ../environment.sh

if [ ${OS_ID} != "freebsd" ]; then
  . /etc/profile.d/nextspace.sh
else
  IS_FREEBSD="/usr/local"
  NEXTSPACE_HOME="/usr/local/NextSpace"
  . ${IS_FREEBSD}/etc/profile.d/nextspace.sh
fi

#----------------------------------------
# Install package dependencies
#----------------------------------------
ECHO ">>> Installing ${OS_ID} packages for NextSpace frameworks build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
  . /Developer/Makefiles/GNUstep.sh
	ECHO "Debian-based Linux distribution: calling 'apt-get install'."
	$PRIV_CMD apt-get install -y ${FRAMEWORKS_BUILD_DEPS}
	$PRIV_CMD apt-get install -y ${FRAMEWORKS_RUN_DEPS}
elif [ ${OS_ID} = "freebsd" ]; then
  . "$($GNUSTEP_CONFIG_CMD --variable=GNUSTEP_MAKEFILES)/GNUstep.sh"
  IS_FREEBSD="1"
else
  . /Developer/Makefiles/GNUstep.sh
	ECHO "RedHat-based Linux distribution: calling 'yum -y install'."
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
$MAKE_CMD || exit 1

#----------------------------------------
# Install
#----------------------------------------
$INSTALL_CMD

exit 0;
if [ "$DEST_DIR" = "" ]; then
	$PRIV_CMD ldconfig
	$LN_CMD /usr/NextSpace/Frameworks/DesktopKit.framework/Resources/25-nextspace-fonts.conf /etc/fonts/conf.d/25-nextspace-fonts.conf
fi
