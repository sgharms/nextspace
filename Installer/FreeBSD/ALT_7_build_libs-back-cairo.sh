#!/bin/sh
# Alternative build script for Cairo graphics backend
# This script downloads gnustep-back 0.32.0 source and builds the Cairo backend.
#
# The default 7_build_libs-back.sh builds the Art backend from vendored source.
# Use this script if you want Cairo backend for better font rendering.

CURPWD=${PWD}
BUILD_ROOT="${CURPWD}/BUILD_ROOT"
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

BUILD_ROOT="${CURPWD}/BUILD_ROOT"
NEXTSPACE_HOME="/usr/local/NextSpace"
. /usr/local/Developer/Makefiles/GNUstep.sh

#----------------------------------------
# Install package dependencies
#----------------------------------------
BACK_CAIRO_DEPS="cairo fontconfig freetype2 libXft libXrender pixman"
echo "Installing Cairo dependencies..."
[ -n "${BACK_CAIRO_DEPS}" ] && $PRIV_CMD pkg install -y ${BACK_CAIRO_DEPS}

#----------------------------------------
# Download gnustep-back source
#----------------------------------------
echo "Downloading gnustep-back 0.32.0 source..."
GNUSTEP_BACK_VERSION="0.32.0"
GNUSTEP_BACK_TARBALL="gnustep-back-${GNUSTEP_BACK_VERSION}.tar.gz"
GNUSTEP_BACK_URL="https://github.com/gnustep/libs-back/releases/download/back-0_32_0/${GNUSTEP_BACK_TARBALL}"

BUILD_DIR=${BUILD_ROOT}/back-cairo

if [ -d ${BUILD_DIR} ]; then
  echo "Removing existing BUILD_ROOT/back-cairo..."
  rm -rf ${BUILD_DIR}
fi

cd ${BUILD_ROOT}
curl -L -o ${GNUSTEP_BACK_TARBALL} ${GNUSTEP_BACK_URL} || {
  echo "Failed to download gnustep-back source" >&2
  exit 1
}

tar -xzf ${GNUSTEP_BACK_TARBALL} || {
  echo "Failed to extract gnustep-back source" >&2
  exit 1
}

mv gnustep-back-${GNUSTEP_BACK_VERSION} back-cairo || {
  echo "Failed to rename source directory" >&2
  exit 1
}

rm -f ${GNUSTEP_BACK_TARBALL}

#----------------------------------------
# Build Cairo backend
#----------------------------------------
cd ${BUILD_DIR}

# Set installation domain for GNUstep build system
export GNUSTEP_INSTALLATION_DOMAIN=SYSTEM
# obsolete, don't be tempted to bake back in; causes make fail
# export GNUSTEP_SYSTEM_ROOT=${NEXTSPACE_HOME}

echo "Configuring Cairo backend for NextSpace..."
./configure \
  --enable-graphics=cairo \
  --with-name=cairo \
  || {
    echo "Configure failed" >&2
    exit 1
  }

echo "Building Cairo backend..."
$MAKE_CMD -j${CPU_COUNT} || {
  echo "Build failed" >&2
  exit 1
}

#----------------------------------------
# Install
#----------------------------------------
echo "Installing Cairo backend..."
$PRIV_CMD env GNUSTEP_INSTALLATION_DOMAIN=SYSTEM $MAKE_CMD install fonts=no || {
  echo "Install failed" >&2
  exit 1
}

#----------------------------------------
# Verify/fix bundle location
#----------------------------------------
CORRECT_LOCATION="${NEXTSPACE_HOME}/Bundles/libgnustep-cairo-032.bundle"
FALLBACK_LOCATION="/usr/local/Library/Bundles/libgnustep-cairo-032.bundle"

if [ -d "${CORRECT_LOCATION}" ]; then
  echo "$(tput setaf 2)Cairo bundle correctly installed to ${CORRECT_LOCATION}$(tput sgr0)"
elif [ -d "${FALLBACK_LOCATION}" ]; then
  echo "$(tput setaf 1)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(tput sgr0)"
  echo "$(tput setaf 1)WARNING: GNUstep build system ignored GNUSTEP_INSTALLATION_DOMAIN=SYSTEM$(tput sgr0)"
  echo "$(tput setaf 1)Bundle installed to LOCAL domain instead of SYSTEM domain.$(tput sgr0)"
  echo "$(tput setaf 1)Applying workaround: moving bundle to correct location...$(tput sgr0)"
  echo "$(tput setaf 1)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(tput sgr0)"
  echo ""
  echo "$(tput setaf 3)TODO: Investigate why downloaded gnustep-back source doesn't respect$(tput sgr0)"
  echo "$(tput setaf 3)GNUSTEP_INSTALLATION_DOMAIN when vendored back-art source does.$(tput sgr0)"
  echo "$(tput setaf 3)Possible solutions to test:$(tput sgr0)"
  echo "$(tput setaf 3)  - Set GNUSTEP_*_BUNDLES environment variables directly$(tput sgr0)"
  echo "$(tput setaf 3)  - Override BUNDLE_INSTALL_DIR in GNUmakefile.preamble$(tput sgr0)"
  echo ""
  $PRIV_CMD mv "${FALLBACK_LOCATION}" "${CORRECT_LOCATION}"
else
  echo "$(tput setaf 1)ERROR: Cairo bundle not found!$(tput sgr0)" >&2
  echo "Expected: ${CORRECT_LOCATION}" >&2
  echo "Or: ${FALLBACK_LOCATION}" >&2
  exit 1
fi

#----------------------------------------
# Update library cache
#----------------------------------------
if [ "$DEST_DIR" = "" ]; then
  echo "Updating library cache..."
  $PRIV_CMD ldconfig -R
fi

#----------------------------------------
# Success message
#----------------------------------------
echo ""
echo "$(tput setaf 2)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Cairo graphics backend installed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(tput sgr0)"
echo ""
echo "The Cairo backend provides superior font rendering, particularly beneficial"
echo "for larger font sizes and users who need clearer text."
echo ""
echo "$(tput setaf 3)To switch to the Cairo backend:$(tput sgr0)"
echo "$(tput setaf 3)Beware! This breaks some icons' appearance.$(tput sgr0)"
echo ""
echo "  defaults write NSGlobalDomain GSBackend libgnustep-cairo-032"
echo ""
echo "$(tput setaf 3)To switch back to Art backend:$(tput sgr0)"
echo ""
echo "  defaults write NSGlobalDomain GSBackend libgnustep-art"
echo ""
echo "$(tput setaf 3)Steven recommends doing$(tput sgr0)"
echo ""
echo "  defaults write Terminal GSBackend libgnustep-cairo-032"
echo ""
echo "$(tput setaf 3)This gives pretty fonts good for coding with the NeXT desktop appearance.$(tput sgr0)"
echo ""
echo "After switching backends, restart Workspace for changes to take effect."
echo ""
