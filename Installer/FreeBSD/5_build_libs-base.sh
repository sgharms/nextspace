#!/bin/sh

CURPWD=${PWD}
BUILD_ROOT="${CURPWD}/BUILD_ROOT"
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

IS_FREEBSD="/usr/local"
NEXTSPACE_HOME="/usr/local/NextSpace"
. ${IS_FREEBSD}/etc/profile.d/nextspace.sh

#----------------------------------------
# Install package dependencies
#----------------------------------------
ECHO ">>> Installing ${OS_ID} packages for GNUstep Base (Foundation) build"
pkg install -y libxslt gnutls pkgconf || { echo "Could not install dependencies" >&2; exit 1;}

. /usr/local/Developer/Makefiles/GNUstep.sh
IS_FREEBSD="1"
GNUSTEP_BACKEND_PORT_DIR="/usr/ports/lang/gnustep-base"
[ -d $GNUSTEP_BACKEND_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)
[ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl"

SOURCES_DIR=${PROJECT_DIR}/Libraries/gnustep
  cd $GNUSTEP_BACKEND_PORT_DIR # We should already be there but...
  PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl NO_DEPENDS=yes"
$BSDMAKE_CMD $PORTS_MAKE_ARGS patch
PORT_SOURCE_DIR=$(find . -name gnustep-base\* -type d | head -1)
if [ -z "$PORT_SOURCE_DIR" ]; then
  echo "Oh no! Couldn't find a directory, was ${PORT_SOURCE_DIR}" >&2
  exit 1
fi
cp -Rf $PORT_SOURCE_DIR ${BUILD_ROOT}/$(basename $PORT_SOURCE_DIR)
cd ${BUILD_ROOT}/$(basename $PORT_SOURCE_DIR)

./configure --with-default-config=${NEXTSPACE_HOME}/Library/Preferences/GNUstep.conf

# NUCLEAR OPTION: Patch the generated config.h directly since ac_cv_func_* exports didn't work
# These functions exist in libdispatch.so but configure fails to detect them
# The configure script must use a custom test instead of standard AC_CHECK_FUNCS
# See /src/FIX_CONFIGURE_DETECTION.md for full explanation
sed -i.bak \
  -e 's|^#undef HAVE__DISPATCH_GET_MAIN_QUEUE_HANDLE_4CF$|#define HAVE__DISPATCH_GET_MAIN_QUEUE_HANDLE_4CF 1|' \
  -e 's|^#undef HAVE__DISPATCH_MAIN_QUEUE_CALLBACK_4CF$|#define HAVE__DISPATCH_MAIN_QUEUE_CALLBACK_4CF 1|' \
  Headers/GNUstepBase/config.h
$MAKE_CMD install debug=yes messages=yes -j12

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
