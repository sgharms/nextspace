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
ECHO ">>> Installing packages for GNUstep GUI (AppKit) build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	. /Developer/Makefiles/GNUstep.sh
	$PRIV_CMD apt-get install -q -y ${GNUSTEP_GUI_DEPS}
elif [ ${OS_ID} = "freebsd" ]; then
  . "$($GNUSTEP_CONFIG_CMD --variable=GNUSTEP_MAKEFILES)/GNUstep.sh"
  IS_FREEBSD="1"
  GNUSTEP_GUI_PORT_DIR="/usr/ports/x11-toolkits/gnustep-gui"
  [ -d $GNUSTEP_GUI_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
  [ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl"
	$PRIV_CMD pkg install -y ${GNUSTEP_GUI_DEPS}
fi

SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep
if ! [ "$IS_FREEBSD" ]; then
	#----------------------------------------
	# Download
	#----------------------------------------
	GIT_PKG_NAME=libs-gui-gui-${gnustep_gui_version}

	if [ ! -d ${BUILD_ROOT}/${GIT_PKG_NAME} ]; then
		curl -L https://github.com/gnustep/libs-gui/archive/gui-${gnustep_gui_version}.tar.gz -o ${BUILD_ROOT}/${GIT_PKG_NAME}.tar.gz
		cd ${BUILD_ROOT}
		tar zxf ${GIT_PKG_NAME}.tar.gz || exit 1
		# Patches
		cd ${BUILD_ROOT}/${GIT_PKG_NAME}
		patch -p1 < ${SOURCES_DIR}/libs-gui_NSApplication.patch
	#	patch -p1 < ${SOURCES_DIR}/libs-gui_GSThemeDrawing.patch
		patch -p1 < ${SOURCES_DIR}/libs-gui_NSPopUpButton.patch
		cd Images
		tar zxf ${SOURCES_DIR}/gnustep-gui-images.tar.gz
	fi

	#----------------------------------------
	# Build
	#----------------------------------------
	cd ${BUILD_ROOT}/${GIT_PKG_NAME} || exit 1
	if [ -d obj ]; then
		$MAKE_CMD clean
	fi
	if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
		./configure --disable-icu-config || exit 1
	else
		./configure || exit 1
	fi
	$MAKE_CMD || exit 1

	#----------------------------------------
	# Install
	#----------------------------------------
	$INSTALL_CMD

	#----------------------------------------
	# Install services
	#----------------------------------------
	$CP_CMD ${SOURCES_DIR}/gpbs.service $DEST_DIR/usr/NextSpace/lib/systemd || exit 1

	if [ "$DEST_DIR" = "" ] && [ "$GITHUB_ACTIONS" != "true" ]; then
		$PRIV_CMD ldconfig
		$PRIV_CMD systemctl daemon-reload || exit 1
		systemctl status gpbs || $PRIV_CMD systemctl enable /usr/NextSpace/lib/systemd/gpbs.service;
	fi
else # IS_FREEBSD
  cd $GNUSTEP_GUI_PORT_DIR # We should already be there but...
  $BSDMAKE_CMD $PORTS_MAKE_ARGS patch
  cd work
  cd $(find . -name libs-gui\* -type d)


  # Patches
  patch -p1 < ${SOURCES_DIR}/libs-gui_NSApplication.patch
	#	patch -p1 < ${SOURCES_DIR}/libs-gui_GSThemeDrawing.patch
  patch -p1 < ${SOURCES_DIR}/libs-gui_NSPopUpButton.patch
  cd Images
  tar zxf ${SOURCES_DIR}/gnustep-gui-images.tar.gz
  cd $GNUSTEP_GUI_PORT_DIR || exit 1

  $BSDMAKE_CMD $PORTS_MAKE_ARGS install
fi # is not BSD
