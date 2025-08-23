#!/bin/sh

. ../environment.sh

if [ ${OS_ID} = "freebsd" ]; then
  # A boolean that can also be used as a prefix
  IS_FREEBSD="freebsd-"
  NEXTSPACE_HOME=/usr/local/NextSpace

  if [ -z "$DEST_DIR" ]; then
    ECHO "FreeBSD detected. Prefixing DEST_DIR to BSD-standard '/usr/local'"
    DEST_DIR="/usr/local"
  fi

  pkg install -y $CORE_SYSTEM_DEPS
fi

#----------------------------------------
# Install system configuration files
#----------------------------------------
CORE_SOURCES=${PROJECT_DIR}/Core/os_files

# /.hidden
$CP_CMD ${CORE_SOURCES}/dot_hidden /.hidden

# Preferences
$MKDIR_CMD $DEST_DIR/Library/Preferences
$CP_CMD ${CORE_SOURCES}/Library/Preferences/* $DEST_DIR/Library/Preferences/

# Linker cache
if ! [ -d $DEST_DIR/etc/ld.so.conf.d ];then
	$MKDIR_CMD -v $DEST_DIR/etc/ld.so.conf.d
fi
$CP_CMD -v ${CORE_SOURCES}/etc/ld.so.conf.d/nextspace.conf $DEST_DIR/etc/ld.so.conf.d/
$PRIV_CMD ldconfig

# X11
$CP_CMD ${CORE_SOURCES}/etc/X11/Xresources.nextspace $DEST_DIR/etc/X11

# PolKit & udev
if ! [ -d $DEST_DIR/etc/polkit-1/rules.d ];then
	$MKDIR_CMD -v $DEST_DIR/etc/polkit-1/rules.d
fi
$CP_CMD ${CORE_SOURCES}/etc/polkit-1/rules.d/*.rules $DEST_DIR/etc/polkit-1/rules.d/

if [ ${OS_ID} != "freebsd" ]; then
  if ! [ -d $DEST_DIR/etc/udev/rules.d ];then
    $MKDIR_CMD -v $DEST_DIR/etc/udev/rules.d
  fi
  $CP_CMD ${CORE_SOURCES}/etc/udev/rules.d/*.rules $DEST_DIR/etc/udev/rules.d/
else
  #/usr/local/etc/devd for vendor additions in *.conf files per devd(8)
  if ! [ -d $DEST_DIR/etc/devd/ ];then
    $MKDIR_CMD -v $DEST_DIR/etc/devd
  fi
  $CP_CMD ${CORE_SOURCES}/etc/devd/*.conf $DEST_DIR/etc/devd/
fi

# User environment
if ! [ -d $DEST_DIR/etc/profile.d ];then
	$MKDIR_CMD -v $DEST_DIR/etc/profile.d
fi

$CP_CMD ${CORE_SOURCES}/etc/profile.d/${IS_FREEBSD}nextspace.sh $DEST_DIR/etc/profile.d/nextspace.sh

if ! [ -d $DEST_DIR/etc/skel ];then
	$MKDIR_CMD -v $DEST_DIR/etc/skel
fi
$CP_CMD ${CORE_SOURCES}/etc/skel/Library $DEST_DIR/etc/skel/
$CP_CMD ${CORE_SOURCES}/etc/skel/.config $DEST_DIR/etc/skel/
$CP_CMD ${CORE_SOURCES}/etc/skel/.emacs.d $DEST_DIR/etc/skel/
$CP_CMD ${CORE_SOURCES}/etc/skel/.gtkrc-2.0 $DEST_DIR/etc/skel/
$CP_CMD ${CORE_SOURCES}/etc/skel/.*.nextspace $DEST_DIR/etc/skel/

# /root
$CP_CMD ${CORE_SOURCES}/etc/skel/.config /root
$CP_CMD ${CORE_SOURCES}/etc/skel/Library /root

# Scripts
if [ "$IS_FREEBSD" ]; then
  if ! [ -d $DEST_DIR/usr/NextSpace/bin ];then
    $MKDIR_CMD -v $DEST_DIR/usr/NextSpace/bin
  fi
  $CP_CMD ${CORE_SOURCES}/usr/NextSpace/bin/* $DEST_DIR/usr/NextSpace/bin/

  # Icons, Plymouth resources and fontconfig configuration
  if ! [ -d $DEST_DIR/usr/share ];then
    $MKDIR_CMD -v $DEST_DIR/usr/share
  fi
  $CP_CMD ${CORE_SOURCES}/usr/share/* $DEST_DIR/usr/share/
else
  if ! [ -d $DEST_DIR/NextSpace/bin ];then
    $MKDIR_CMD -v $DEST_DIR/NextSpace/bin
  fi
  $CP_CMD ${CORE_SOURCES}/usr/NextSpace/bin/* $DEST_DIR/NextSpace/bin/

  # Icons, Plymouth resources and fontconfig configuration
  if ! [ -d $DEST_DIR/share ];then
    $MKDIR_CMD -v $DEST_DIR/share
  fi
  $CP_CMD ${CORE_SOURCES}/usr/share/* $DEST_DIR/share/
fi
