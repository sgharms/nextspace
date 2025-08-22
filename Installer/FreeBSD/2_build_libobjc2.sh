#!/bin/sh

CURPWD=${PWD}
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

#----------------------------------------
# Install package dependencies
#----------------------------------------
echo "Using system libobjc2 from ports, skipping vendored build"
LIBOBJC2_PORT_DIR="/usr/ports/lang/libobjc2/"
ROBIN_MAP_PORT_DIR="/usr/ports/devel/robin-map"

$PRIV_CMD pkg install -y ${BUILD_TOOLS} || exit 1
[ "$NEXTSPACE_HOME" ] || NEXTSPACE_HOME=/usr/local/NextSpace

[ -d $ROBIN_MAP_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)

[ -d $LIBOBJC2_PORT_DIR ] || echo $(cat << EOF 1>&2
FreeBSD installation relies on the ports(7) infrastructure.

Please make sure you have cloned https://git.FreeBSD.org/ports.git
EOF
)

[ "$PORTS_MAKE_ARGS" ] || PORTS_MAKE_ARGS="DEFAULT_VERSIONS+=ssl=openssl NO_DEPENDS=1"

cd $ROBIN_MAP_PORT_DIR
$BSDMAKE_CMD $PORTS_MAKE_ARGS install || { echo "Install of Robin Map port failed"; exit 1; }

cd $LIBOBJC2_PORT_DIR
$BSDMAKE_CMD $PORTS_MAKE_ARGS clean install || { echo "Install of libobjc2 port failed"; exit 1; }

if [ "$DEST_DIR" = "" ]; then
    $PRIV_CMD ldconfig -R
fi
