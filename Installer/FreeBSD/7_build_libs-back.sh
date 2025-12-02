#!/bin/sh

CURPWD=${PWD}
BUILD_ROOT="${CURPWD}/BUILD_ROOT"
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

BUILD_ROOT="${CURPWD}/BUILD_ROOT"
NEXTSPACE_HOME="/usr/local/NextSpace"
GNUSTEP_BACK_PORT_DIR="/usr/ports/x11-toolkits/gnustep-back"
[ -d $GNUSTEP_BACK_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
[ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl NO_DEPENDS=1"
. /usr/local/Developer/Makefiles/GNUstep.sh

#----------------------------------------
# Install package dependencies
#----------------------------------------
[ -n "${BACK_ART_DEPS}" ] && $PRIV_CMD pkg install -y ${BACK_ART_DEPS}

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

$MAKE_CMD -j${CPU_COUT} || exit 1

#----------------------------------------
# Install
#----------------------------------------
$INSTALL_CMD fonts=no || exit 1

echo "Installing additional Cairo-based back end for higher-resolution functions, where beneficial."

cd $GNUSTEP_BACK_PORT_DIR
$BSDMAKE_CMD $PORTS_MAKE_ARGS patch
PORT_SOURCE_DIR=$(find . -name libs-back\* -type d)
if [ -z "$PORT_SOURCE_DIR" ]; then
  echo "Oh no! Couldn't find a directory, was ${PORT_SOURCE_DIR}" >&2
  exit 1
fi

cp -Rf $PORT_SOURCE_DIR ${BUILD_ROOT}/$(basename $PORT_SOURCE_DIR)
cd ${BUILD_ROOT}/$(basename $PORT_SOURCE_DIR)
./configure --with-default-config=/usr/local/Library/Preferences/GNUstep.conf

$MAKE_CMD install || { echo "Install of gnustep-back port failed"; exit 1; }

echo "Installed $(basename $PORT_SOURCE_DIR)"

if [ "$DEST_DIR" = "" ]; then
  $PRIV_CMD ldconfig -R
fi

ECHO "$(tput setaf 3 bold)MANUAL INTERVENTION REQUIRED!"
ECHO "$(tput sgr0)"
ECHO "In your rc file, launch the GNUStep PasteBoard Service (gpbs)"
ECHO "and distributed notifications center (gdnc)"
ECHO ""
ECHO "/usr/local/Library/bin/gpbs"
ECHO "/usr/local/Library/bin/gdnc"
ECHO ""
ECHO "$(tput setaf 3 bold)END TRANSMISSION"
ECHO "$(tput sgr0)"
