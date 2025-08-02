#!/bin/sh

. ../environment.sh

#----------------------------------------
# Install system configuration files
#----------------------------------------
CORE_SOURCES=${PROJECT_DIR}/Core/os_files

# /.hidden
$CP_CMD ${CORE_SOURCES}/dot_hidden /.hidden

if ! [ -z $IS_FREEBSD ]; then
  if ! [ "$DEST_DIR" = "/usr/local" ]; then
    printf "%sYou are on FreeBSD and don't have DEST_DIR set to '/usr/local'. This is almost certainly a mistake\n%s" $(tput setaf 226) $(tput sgr0)
    printf "Use ^C to abort and reinvoke with \"DEST_DIR=/usr/local\". Otherwise, press enter to continue. \n ";
    read FU
  fi
fi

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
# We've not yet installed the X ecosystem, test for presence.
if ! [ -d "$DEST_DIR/etc/X11" ]; then
  $MKDIR_CMD "$DEST_DIR/etc/X11"
fi
$CP_CMD ${CORE_SOURCES}/etc/X11/Xresources.nextspace $DEST_DIR/etc/X11

# PolKit & udev
if ! [ -d $DEST_DIR/etc/polkit-1/rules.d ];then
	$MKDIR_CMD -v $DEST_DIR/etc/polkit-1/rules.d
fi
$CP_CMD ${CORE_SOURCES}/etc/polkit-1/rules.d/*.rules $DEST_DIR/etc/polkit-1/rules.d/

if ! [ $IS_FREEBSD ]; then
  # FreeBSD uses `devd`
  if ! [ -d $DEST_DIR/etc/udev/rules.d ];then
    $MKDIR_CMD -v $DEST_DIR/etc/udev/rules.d
  fi
  $CP_CMD ${CORE_SOURCES}/etc/udev/rules.d/*.rules $DEST_DIR/etc/udev/rules.d/
fi

# User environment
if ! [ -d $DEST_DIR/etc/profile.d ];then
	$MKDIR_CMD -v $DEST_DIR/etc/profile.d
fi
$CP_CMD ${CORE_SOURCES}/etc/profile.d/nextspace.sh $DEST_DIR/etc/profile.d/

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
if [ $IS_FREEBSD ]; then
  if ! [ "$NEXTSPACE_ROOT" = "/usr/local/NextSpace" ]; then
    printf "%sYou are on FreeBSD and don't have NEXTSPACE_ROOT set to '/usr/local/NextSpace'. This is almost certainly a mistake.\n%s" $(tput setaf 226) $(tput sgr0)
    printf "%sUse ^C to abort and reinvoke with \"NEXTSPACE_ROOT=/usr/local/NextSpace\". Otherwise, press enter to continue.\n%s" $(tput setaf 226) $(tput sgr0)
    read FU
  fi

  if ! [ -d $NEXTSPACE_ROOT/bin ];then
    $MKDIR_CMD -v $NEXTSPACE_ROOT/bin
  fi
  $CP_CMD ${CORE_SOURCES}/usr/NextSpace/bin/* $NEXTSPACE_ROOT/bin/

  # Icons, Plymouth resources and fontconfig configuration
  if ! [ -d $DEST_DIR/share ]; then
    $MKDIR_CMD -v $DEST_DIR/share
  fi
  $CP_CMD ${CORE_SOURCES}/usr/share/* $DEST_DIR/share/

  # No Plymouth for FreeBSD
  rm -rf $DEST_DIR/share/plymouth
else

  if ! [ -d $NEXTSPACE_ROOT/bin ];then
    $MKDIR_CMD -v $NEXTSPACE_ROOT/bin
  fi
  $CP_CMD ${CORE_SOURCES}/usr/NextSpace/bin/* $NEXTSPACE_ROOT/bin/

  # Icons, Plymouth resources and fontconfig configuration
  if ! [ -d $DEST_DIR/usr/share ];then
    $MKDIR_CMD -v $DEST_DIR/usr/share
  fi
  $CP_CMD ${CORE_SOURCES}/usr/share/* $DEST_DIR/usr/share/
fi
