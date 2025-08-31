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
ECHO ">>> Installing packages for GNUstep GUI Backend (ART) build"
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
. /Developer/Makefiles/GNUstep.sh
	$PRIV_CMD apt-get install -y ${BACK_ART_DEPS}
elif [ ${OS_ID} = "freebsd" ]; then
  . "$($GNUSTEP_CONFIG_CMD --variable=GNUSTEP_MAKEFILES)/GNUstep.sh"
  IS_FREEBSD="1"
  GNUSTEP_BACK_PORT_DIR="/usr/ports/x11-toolkits/gnustep-back"
  [ -d $GNUSTEP_BACK_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
  [ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl"
fi

#----------------------------------------
# Download
#----------------------------------------
SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep
if ! [ "$IS_FREEBSD" ]; then
  BUILD_DIR=${BUILD_ROOT}/back-art

  if [ -d ${BUILD_DIR} ]; then
    rm -rf ${BUILD_DIR}
  fi
  cp -R ${SOURCES_DIR}/back-art ${BUILD_ROOT}

  #----------------------------------------
  # Build
  #----------------------------------------
  cd ${BUILD_DIR}

  ./configure \
    --enable-graphics=art \
    --with-name=art \
    || exit 1

  $MAKE_CMD || exit 1

  #----------------------------------------
  # Install
  #----------------------------------------
  $INSTALL_CMD fonts=no || exit 1

  if [ "$DEST_DIR" = "" ]; then
    $PRIV_CMD ldconfig
  fi
else # IS_FREEBSD
  cd $GNUSTEP_BACK_PORT_DIR
  # I couldn't find any `fonts=no` variables in ./configure --help. Not
  # retaining.
  $BSDMAKE_CMD GNU_CONFIGURE=yes CONFIGURE_ARGS"=--enable-graphics=art --with-name=art" install

	#----------------------------------------
	# Install services
	#----------------------------------------
  ECHO "$(tput setaf 3 bold)MANUAL INTERVENTION REQUIRED!"
  ECHO "$(tput sgr0)"
  ECHO "You should start the GNUStep Pasteboard Service (inter-application copy-and-paste) by adding"
  ECHO "the following to your login rc file (.shrc, .bashrc, etc.)."
  ECHO ""
  ECHO "/usr/local/GNUstep/System/Tools/gpbs"
  ECHO ""
  ECHO "For more, see gpbs(1) as provided in the gnustep-back port."
  ECHO ""
  ECHO "$(tput setaf 3 bold)END TRANSMISSION"
  ECHO "$(tput sgr0)"
fi
