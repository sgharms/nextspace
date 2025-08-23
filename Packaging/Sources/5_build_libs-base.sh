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
ECHO ">>> Installing ${OS_ID} packages for GNUstep Base (Foundation) build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
  . /Developer/Makefiles/GNUstep.sh
	ECHO "Debian-based Linux distribution: calling 'apt-get install'."
	$PRIV_CMD apt-get install -y ${GNUSTEP_BASE_DEPS} || exit 1
elif [ ${OS_ID} = "freebsd" ]; then
  . "$($GNUSTEP_CONFIG_CMD --variable=GNUSTEP_MAKEFILES)/GNUstep.sh"
  IS_FREEBSD="1"
  GNUSTEP_BACKEND_PORT_DIR="/usr/ports/lang/gnustep-base"
  [ -d $GNUSTEP_BACKEND_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
  [ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl NO_DEPENDS=1"
  if ! [ "$SKIP_DEPS" ]; then
    ECHO "$(tput setaf 1)This port pulls in the X11 universe and make take a minute. Make a coffee."
    ECHO "$(tput setaf 1)We will install non-prime dependencies via pkg(8) for speed$(tput sgr0)"
    cd $GNUSTEP_BACKEND_PORT_DIR
    # list all dependencies of this port
    $BSDMAKE_CMD $PORTS_MAKE_ARGS all-depends-list \
      | grep -v '/gnustep-' \
      | sed 's|/usr/ports/||' \
      | xargs pkg install -y
  fi
else
  . /Developer/Makefiles/GNUstep.sh
	ECHO "RedHat-based Linux distribution: calling 'yum -y install'."
	SPEC_FILE=${PROJECT_DIR}/Libraries/gnustep/nextspace-gnustep.spec
	DEPS=`rpmspec -q --buildrequires ${SPEC_FILE} | grep -v libobjc2 | awk -c '{print $1}'`
	$PRIV_CMD yum -y install ${DEPS} || exit 1
fi

SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep
if ! [ "$IS_FREEBSD" ]; then
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

  $MKDIR_CMD $DEST_DIR/usr/NextSpace/etc
  $CP_CMD ${SOURCES_DIR}/gdomap.interfaces $DEST_DIR/usr/NextSpace/etc/
  $MKDIR_CMD $DEST_DIR/usr/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdomap.service $DEST_DIR/usr/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdnc.service $DEST_DIR/usr/NextSpace/lib/systemd
  $CP_CMD ${SOURCES_DIR}/gdnc-local.service $DEST_DIR/usr/NextSpace/lib/systemd

  if [ "$DEST_DIR" = "" ] && [ "$GITHUB_ACTIONS" != "true" ]; then
    $PRIV_CMD ldconfig
    $PRIV_CMD systemctl daemon-reload
    systemctl status gdomap || $PRIV_CMD systemctl enable /usr/NextSpace/lib/systemd/gdomap.service;
    systemctl status gdnc || $PRIV_CMD systemctl enable /usr/NextSpace/lib/systemd/gdnc.service;
    $PRIV_CMD systemctl enable /usr/NextSpace/lib/systemd/gdnc-local.service;
    $PRIV_CMD systemctl start gdomap gdnc
  fi
else # IS_FREEBSD
  cd $GNUSTEP_BACKEND_PORT_DIR # We should already be there but...
  $BSDMAKE_CMD $PORTS_MAKE_ARGS install

	# Daemons, etc.
  $MKDIR_CMD "${NEXTSPACE_HOME}/etc"
  $CP_CMD ${SOURCES_DIR}/gdomap.interfaces "${NEXTSPACE_HOME}/etc"
  $CP_CMD ${SOURCES_DIR}/freebsd/gdomap /usr/local/etc/rc.d

  ECHO "$(tput setaf 3 bold)MANUAL INTERVENTION REQUIRED!"
  ECHO "$(tput sgr0)"
  ECHO "A gdomap startup script has been copied to /usr/local/etc/rc.d. It should be enabled"
  ECHO "to start on boot with (as root):"
  ECHO ""
  ECHO "# sysrc gdomap_enable=\"YES\""
  ECHO ""
  ECHO "For more, see gdomap(8) as provided in the gnustep-base port."
  ECHO ""
  ECHO "$(tput setaf 3 bold)END TRANSMISSION"
  ECHO "$(tput sgr0)"
fi # ! [ "$IS_FREEBSD" ]
