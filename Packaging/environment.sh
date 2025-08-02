###############################################################################
# Variables
###############################################################################
_PWD=`pwd`
# Prefer doas(1) to sudo(1)
#
if [ $(id -u) = 0 ]; then
  PRIV_CMD=""
else
  if [ -e "/usr/local/etc/doas.conf" ]; then
    PRIV_CMD="doas"
  else
    PRIV_CMD="sudo"
  fi
fi
export PRIV_CMD

#----------------------------------------
# Libraries and applications
#----------------------------------------
# Apple
libdispatch_version=5.10
libcorefoundation_version=5.10
libcfnetwork_version=129.20
# GNUstep
libobjc2_version=2.2.1
gnustep_make_version=2_9_2
gnustep_base_version=1_31_1
gnustep_gui_version=0_32_0
gorm_version=1_5_0
projectcenter_version=0_7_0

#----------------------------------------
# Operating system
#----------------------------------------
. /etc/os-release
# OS type like "rhel"
OS_LIKE=`echo ${ID_LIKE} | awk '{print $1}'`
# OS name like "fedora"
OS_ID=$ID
_ID=`echo ${ID} | awk -F\" '{print $2}'`
if [ -n "${_ID}" ] && [ "${_ID}" != " " ]; then
  OS_ID=${_ID}
fi
# OS version like "39"
OS_VERSION=$VERSION_ID
_VER=`echo ${VERSION_ID} | awk -F\. '{print $1}'`
if [ -n "${_VER}" ] && [ "${_VER}" != " " ]; then
  OS_VERSION=$_VER
fi
# Name like "Fedora Linux"
OS_NAME=$NAME
printf "OS:\t\t%s-%s\n" $OS_ID $OS_VERSION

#---------------------------------------
# Machine
#---------------------------------------
MACHINE=`uname -m`
if [ -f /proc/device-tree/model ];then
	MODEL=`cat /proc/device-tree/model | awk '{print $1}'`
else
	MODEL="unknown"
fi

if [ -f /proc/device-tree/compatible ];then
	GPU=`tr -d '\0' < /proc/device-tree/compatible | awk -F, '{print $3}'`
else
	GPU="unknown"
fi

#----------------------------------------
# Paths
#----------------------------------------
# Directory where nextspace GitHub repo resides
cd ../..
PROJECT_DIR=`pwd`
printf "NextSpace repo(PROJECT_DIR):\t%s\n" $PROJECT_DIR
cd ${_PWD}

if [ -z $BUILD_RPM ]; then
  if [ -z $BUILD_ROOT ]; then
    # Environment variables take precedence
    export BUILD_ROOT="${_PWD}/BUILD_ROOT"
  fi
  if [ ! -d ${BUILD_ROOT} ]; then
    mkdir ${BUILD_ROOT}
  fi

  printf "Build in:\t%s\n" $BUILD_ROOT

  if [ "$1" != "" ];then
    DEST_DIR=${1}
    printf "Install in(DEST_DIR):\t%s\n" $DEST_DIR
  else
    # Allow for setting via environment
    if [ -z "$DEST_DIR" ]; then
      DEST_DIR=""
    fi
  fi
else
  print_H2 "===== Create rpmbuild directories..."
  RELEASE_USR="$_PWD/$OS_ID-$OS_VERSION/NSUser"
  RELEASE_DEV="$_PWD/$OS_ID-$OS_VERSION/NSDeveloper"
  mkdir -p ${RELEASE_USR}
  mkdir -p ${RELEASE_DEV}

  RPM_SOURCES_DIR=~/rpmbuild/SOURCES
  RPM_SPECS_DIR=~/rpmbuild/SPECS
  RPMS_DIR=~/rpmbuild/RPMS/`uname -m`
  mkdir -p $RPM_SOURCES_DIR
  mkdir -p $RPM_SPECS_DIR

  printf "RPMs directory:\t%s\n" $RPMS_DIR
fi

. ../functions.sh
#----------------------------------------
# Package dependencies
#----------------------------------------
if [ ${OS_ID} = "debian" ] || [ ${OS_ID} = "ubuntu" ]; then
    . ./${OS_ID}-${OS_VERSION}.deps.sh || exit 1
elif [ "${OS_ID}" = "freebsd" ]; then
    . ./${OS_ID}.deps.sh
    export IS_FREEBSD=1
    export ECHO="printf "%s\n""
else
    prepare_redhat_environment
fi

#----------------------------------------
# Tools
#----------------------------------------
# Make
  CMAKE_CMD=cmake
if type "gmake" 2>/dev/null >/dev/null ;then
  MAKE_CMD="gmake -j8 "
else
  MAKE_CMD="make -j8 "
fi
#
if [ "$1" != "" ];then
  INSTALL_CMD="${MAKE_CMD} install DESTDIR=${1}"
else
  INSTALL_CMD="${PRIV_CMD} ${PRIV_CMD:+ -E} ${MAKE_CMD} install"
fi

# Utilities
if [ "$1" != "" ];then
  RM_CMD="rm"
  LN_CMD="ln -sf"
  MV_CMD="mv -v"
  CP_CMD="cp -R"
  MKDIR_CMD="mkdir -p"
else
  RM_CMD="${PRIV_CMD} rm"
  LN_CMD="${PRIV_CMD} ln -sf"
  MV_CMD="${PRIV_CMD} mv -v"
  CP_CMD="${PRIV_CMD} cp -R"
  MKDIR_CMD="${PRIV_CMD} mkdir -p"
fi

# Linker
if [ "${OS_ID}" != "freebsd" ]; then
  ld -v | grep "gold" 2>&1 > /dev/null
  if [ "$?" = "1" ]; then
    echo "Setting up Gold linker..."
    sudo update-alternatives --install /usr/bin/ld ld /usr/bin/ld.gold 100
    sudo update-alternatives --install /usr/bin/ld ld /usr/bin/ld.bfd 10
    sudo update-alternatives --auto ld
    ld -v | grep "gold" 2>&1 > /dev/null
    if [ "$?" = "1" ]; then
      echo "Failed to setup Gold linker"
      exit 1
    fi
  fi
elif [ "${OS_ID}" = "freebsd" ]; then
  printf "Using linker:\t%s\n" "$(ld --version)"
  printf "\t\tPer ld.lld(1): \"...drop-in replacement for the GNU BFD and gold linkers\""
else
  printf "Using linker:\t%s\n" Gold
fi

# Compiler
if [ "$OS_ID" = "fedora" ] || [ "$OS_LIKE" = "rhel" ] || [ "$OS_ID" = "debian" ] || [ "$OS_ID" = "ubuntu" ] || [ "$OS_ID" = "ultramarine" ] || [ "$OS_ID" = "freebsd" ]; then
  which clang 2>&1 > /dev/null || { echo "No clang compiler found. Please install clang package."; exit 1; }
  export C_COMPILER=`which clang`
  which clang++ 2>&1 > /dev/null || { echo "No clang++ compiler found. Please install clang++ package."; exit 1; }
  export CXX_COMPILER=`which clang++`
fi
