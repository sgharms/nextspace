#!/bin/sh

. ../environment.sh
. "${PROJECT_DIR}/Core/nextspace${IS_FREEBSD:+-freebsd}.fsl"
. "${GNUSTEP_MAKEFILES}/GNUstep.sh"
. ${DEST_DIR}/etc/profile.d/nextspace.sh

if ! [ -z $IS_FREEBSD ]; then
  if ! [ "$DEST_DIR" = "/usr/local" ]; then
    printf "%sYou are on FreeBSD and don't have DEST_DIR set to '/usr/local'. This is almost certainly a mistake\n%s" $(tput setaf 226) $(tput sgr0)
    printf "Use ^C to abort and reinvoke with \"DEST_DIR=/usr/local\". Otherwise, press enter to continue. \n ";
    read FU
  fi
fi

#----------------------------------------
# Install package dependecies
#----------------------------------------
${ECHO} ">>> Installing ${OS_ID} packages for GNUstep Base (Foundation) build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	${ECHO} "Debian-based Linux distribution: calling 'apt-get install'."
	sudo apt-get install -y ${GNUSTEP_BASE_DEPS} || exit 1
elif [ $IS_FREEBSD ]; then
  $PRIV_CMD pkg install -y ${GNUSTEP_BASE_DEPS}
else
	${ECHO} "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Libraries/gnustep/nextspace-gnustep.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | grep -v libobjc2 | awk -c '{print $1}'`
	sudo yum -y install ${DEPS} || exit 1
fi

#----------------------------------------
# Download
#----------------------------------------
GIT_PKG_NAME=libs-base-base-${gnustep_base_version}

if [ ! -d ${BUILD_ROOT}/${GIT_PKG_NAME} ]; then
	curl -L https://github.com/gnustep/libs-base/archive/base-${gnustep_base_version}.tar.gz -o ${BUILD_ROOT}/${GIT_PKG_NAME}.tar.gz
	cd ${BUILD_ROOT}
	tar zxf ${GIT_PKG_NAME}.tar.gz || exit 1
	cd ..
fi

#----------------------------------------
# Build
#----------------------------------------
cd ${BUILD_ROOT}/${GIT_PKG_NAME} || exit 1
if [ -d obj ]; then
	$MAKE_CMD clean
fi
./configure || exit 1
$MAKE_CMD || exit 1

#----------------------------------------
# Install
#----------------------------------------
$INSTALL_CMD
cd ${_PWD}

#----------------------------------------
# Install services
#----------------------------------------
SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep

if [ $IS_FREEBSD ]; then
  $MKDIR_CMD $DEST_DIR/NextSpace/etc
  $CP_CMD ${SOURCES_DIR}/gdomap.interfaces $DEST_DIR/NextSpace/etc/
  $MKDIR_CMD $DEST_DIR/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdomap.service $DEST_DIR/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdnc.service $DEST_DIR/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdnc-local.service $DEST_DIR/NextSpace/lib/systemd
  printf "%s%s%s\n" $(tput setaf 1) "gdomap and gdnc are not enabled because I haven't figure out FreeBSD analogs." $(tput sgr0)
  printf "%s%s%s\n" $(tput setaf 1) "Stub implementations from the Linux version have been copied." $(tput sgr0)
else
  $MKDIR_CMD $DEST_DIR/usr/NextSpace/etc
  $CP_CMD ${SOURCES_DIR}/gdomap.interfaces $DEST_DIR/usr/NextSpace/etc/
  $MKDIR_CMD $DEST_DIR/usr/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdomap.service $DEST_DIR/usr/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdnc.service $DEST_DIR/usr/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdnc-local.service $DEST_DIR/usr/NextSpace/lib/systemd

  if [ "$DEST_DIR" = "" ] && [ "$GITHUB_ACTIONS" != "true" ]; then
    sudo ldconfig
    sudo systemctl daemon-reload
    systemctl status gdomap || sudo systemctl enable /usr/NextSpace/lib/systemd/gdomap.service;
    systemctl status gdnc || sudo systemctl enable /usr/NextSpace/lib/systemd/gdnc.service;
    sudo systemctl enable /usr/NextSpace/lib/systemd/gdnc-local.service;
    sudo systemctl start gdomap gdnc
  fi
fi
