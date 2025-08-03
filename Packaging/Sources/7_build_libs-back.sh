#!/bin/sh

. ../environment.sh
. "${PROJECT_DIR}/Core/nextspace${IS_FREEBSD:+-freebsd}.fsl"
. "${GNUSTEP_MAKEFILES}/GNUstep.sh"
. ${DEST_DIR}/etc/profile.d/nextspace.sh

#----------------------------------------
# Install package dependecies
#----------------------------------------
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
	${ECHO} ">>> Installing packages for GNUstep GUI Backend (ART) build"
	sudo apt-get install -y ${BACK_ART_DEPS}
elif [ $IS_FREEBSD ]; then
  pkg install -y ${BACK_ART_DEPS}
fi

#----------------------------------------
# Download
#----------------------------------------
SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep
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

if [ $IS_FREEBSD ]; then
  # gpbs(1) Every user needs to have his own instance of gpbs running...
  # recommended to start gpbs in a personal login script like ~/.bashrc  or
  # ~/.cshrc.
  #
  # TODO: It's a bit weird that we're setting the systemd files in the previous
  # stage. Should probably move to this stage.
  printf "%sEnsure you're sourcing %s in your shell login profile.\n%s" $(tput setaf 2) "${GNUSTEP_MAKEFILES}/GNUstep.sh" $(tput sgr0)
  printf "%sPer gpbs(1), launch %s as part of your shell login profile.\n%s" $(tput setaf 2) "$(/usr/local/NextSpace/bin/gnustep-config --variable=GNUSTEP_LOCAL_TOOLS)/gpbs" $(tput sgr0)
fi
