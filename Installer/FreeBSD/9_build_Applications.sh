#!/bin/sh

CURPWD=${PWD}
BUILD_ROOT="${CURPWD}/BUILD_ROOT"
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

_PWD=`pwd`

#----------------------------------------
# Install package dependecies
#----------------------------------------
ECHO ">>> Installing ${OS_ID} packages for NextSpace applications build"
. /usr/local/etc/profile.d/nextspace.sh
. /usr/local/Developer/Makefiles/GNUstep.sh
IS_FREEBSD=1
BUILD_ROOT="${CURPWD}/BUILD_ROOT"
$PRIV_CMD pkg install -y ${APPS_RUN_DEPS}
/usr/local/bin/fc-cache -fv

#----------------------------------------
# Download
#----------------------------------------
SOURCES_DIR=${PROJECT_DIR}
APP_BUILD_DIR=${BUILD_ROOT}/Applications
GORM_BUILD_DIR=${BUILD_ROOT}/gorm-${gorm_version}
PC_BUILD_DIR=${BUILD_ROOT}/projectcenter-${projectcenter_version}

if [ -d ${APP_BUILD_DIR} ]; then
	$PRIV_CMD rm -rf ${APP_BUILD_DIR}
fi
cp -R ${SOURCES_DIR}/Applications ${BUILD_ROOT}

# GORM
if [ -z "${SKIP_GORM_PC}" ]; then
	if [ -d ${GORM_BUILD_DIR} ]; then
		$PRIV_CMD rm -rf ${GORM_BUILD_DIR}
	fi
	git_remote_archive https://github.com/gnustep/apps-gorm ${GORM_BUILD_DIR} gorm-${gorm_version}
else
	ECHO ">>> Skipping GORM download (SKIP_GORM_PC is set)"
fi

# ProjectCenter
if [ -z "${SKIP_GORM_PC}" ]; then
	if [ -d ${PC_BUILD_DIR} ]; then
		$PRIV_CMD rm -rf ${PC_BUILD_DIR}
	fi
	git_remote_archive https://github.com/gnustep/apps-projectcenter ${PC_BUILD_DIR} projectcenter-${projectcenter_version}
else
	ECHO ">>> Skipping ProjectCenter download (SKIP_GORM_PC is set)"
fi

#----------------------------------------
# Build
#----------------------------------------
. /usr/local/Developer/Makefiles/GNUstep.sh

# This is worth calling out. The Applications *must* be installed in order
# Workspace depends on e.g. Preferences' data being in the expected
# GNUStep .fsl-specified directory

cd ${APP_BUILD_DIR}
export CC=${C_COMPILER}
export CMAKE=${CMAKE_CMD}
$MAKE_CMD clean
$MAKE_CMD -j${CPU_COUNT} || exit 1
$MAKE_CMD install GNUSTEP_INSTALLATION_DOMAIN=SYSTEM || exit

export GNUSTEP_INSTALLATION_DOMAIN=SYSTEM
if [ -z "${SKIP_GORM_PC}" ]; then
	cd ${GORM_BUILD_DIR}
	tar zxf ${SOURCES_DIR}/Libraries/gnustep/gorm-images.tar.gz
	patch -p1 < ${SOURCES_DIR}/Libraries/gnustep/gorm.patch
	$MAKE_CMD
	$MAKE_CMD install || exit
else
	ECHO ">>> Skipping GORM build/install (SKIP_GORM_PC is set)"
fi

if [ -z "${SKIP_GORM_PC}" ]; then
	cd ${PC_BUILD_DIR}
	tar zxf ${SOURCES_DIR}/Libraries/gnustep/projectcenter-images.tar.gz
	patch -p1 < ${SOURCES_DIR}/Libraries/gnustep/pc.patch
	$MAKE_CMD
	$MAKE_CMD install || exit
else
	ECHO ">>> Skipping ProjectCenter build/install (SKIP_GORM_PC is set)"
fi

  $PRIV_CMD ldconfig -R

#  # Set Terminal.app to use big fonts!
## defaults write Terminal GSBackend libgnustep-back
## defaults write NSGlobalDomain GSBackend libgnustep-art
## defaults write NSGlobalDomain GSBackend libgnustep-back
## defaults write Terminal GSBackend libgnustep-back
## defaults write Terminal TerminalFontSize 24
# Restore global/system default (if you’d set it before)
#defaults delete NSGlobalDomain GSBackend
ECHO "$(tput setaf 2 bold)Good news!"
ECHO "NextSpace has been installed for FreeBSD."
ECHO ""
ECHO "NOTE: Graphical login has not been configured."
ECHO "NOTE: Sound is temporarily disabled"
ECHO "$(tput setaf 3 bold)Reminder"
ECHO ""
ECHO "Make sure you have dbus running:"
ECHO ""
ECHO "# sysrc dbus_enable=\"YES\""
ECHO "$(tput sgr0)"
