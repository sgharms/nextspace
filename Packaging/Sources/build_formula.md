## Setup

1. Pristine 14.3 Jail; create snapshot: `zroot/jails/containers/nextspace@add-pkg-20250802-001`
2. Mount WIP codebase to /src in the jail
3. Access jail as root

## Quick Reference

* Rollback: `zfs rollback zroot/jails/containers/nextspace@add-pkg-20250802-001`
* Create Snapshot: `zfs snapshot zroot/jails/containers/nextspace@TEXT-$(date +%Y%m%d-%H%M)`
*  echo "alias jj='cd /src/Packaging/Sources'" >> ~/.shrc

## Installation

### Step 0

Chant: `DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build sh 0_build_libdispatch.sh`

### Step 1

#### Test Case: No NextSpace Root

Chant: `DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build  sh 1_build_libcorefoundation.sh`
=> Warning Text [OK]

#### Test Case: NextSpace Root; Using Non-FreeBSD Aware CFNetwork

Chant: `NEXTSPACE_ROOT=/usr/local/NextSpace DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build  sh -x 1_build_libcorefoundation.sh`
=> Dies as expected [OK]

#### NetSpace Root using WIP CFNetwork

`NEXTSPACE_ROOT=/usr/local/NextSpace DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build ALT_CFNET_GIT_CMD="git clone --depth 1 -b add-freebsd-support https://github.com/sgharms/apple-cfnetwork" sh 1_build_libcorefoundation.sh`

### Step 2 -- objective c

NEXTSPACE_ROOT=/usr/local/NextSpace DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build sh -x 2_build_libobjc2.sh

### Step 3-build_core

Chant: `NEXTSPACE_ROOT=/usr/local/NextSpace DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build sh -xe 3_build_core.sh`

### Step 3-build_...-make

NEXTSPACE_ROOT=/usr/local/NextSpace DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build sh -xe 3_build_tools-make.sh

    Creating system tools directory: /NextSpace/bin
    Creating makefile directories in: /usr/local/share/GNUstep/Makefiles
    Installing GNUstep configuration file in /usr/local/Library/Preferences/GNUstep.conf

### 4 Libwraster

`NEXTSPACE_ROOT=/usr/local/NextSpace DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build sh 4_build_libwraster.sh `

### 5 gnustep base

`NEXTSPACE_ROOT=/usr/local/NextSpace DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build sh 5_build_libs-base.sh`

`/root/.shrc`
```sh
# NextSpace
. /usr/local/share/GNUstep/Makefiles/GNUstep.sh
/usr/local/Library/bin/gdnc
```

### 6 libs-gui

`NEXTSPACE_ROOT=/usr/local/NextSpace DEST_DIR=/usr/local BUILD_ROOT=/tmp/Build sh 6_build_libs-gui.sh 

### 7 libs-back

`/root/.shrc`
```sh
# NextSpace
. /usr/local/share/GNUstep/Makefiles/GNUstep.sh
/usr/local/Library/bin/gpbs
```

### 8 Frameworks

pkg install -y xorg-server libXcursor libXrandr libdbus
gmake clean
export ADDITIONAL_CPPFLAGS="$(pkg-config --cflags dbus-1)" ADDITIONAL_OBJCFLAGS="-DFREEBSD -UWITH_HAL"
gmake
