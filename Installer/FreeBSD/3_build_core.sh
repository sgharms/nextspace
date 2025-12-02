#!/bin/sh

CURPWD=${PWD}
BUILD_ROOT="${CURPWD}/BUILD_ROOT"
cd ../../Packaging/Sources
.  ../environment.sh
cd $CURPWD

# A boolean that can also be used as a prefix
IS_FREEBSD="freebsd-"
NEXTSPACE_HOME=/usr/local/NextSpace

if [ -z "$DEST_DIR" ]; then
  ECHO "FreeBSD detected. Prefixing DEST_DIR to BSD-standard '/usr/local'"
  DEST_DIR="/usr/local"
fi

pkg install -y $CORE_SYSTEM_DEPS || { echo "Failed to install core dependency. Aborting"; exit 1; }

#----------------------------------------
# Install system configuration files
#----------------------------------------
CORE_SOURCES=${PROJECT_DIR}/Core/os_files

# /.hidden
$CP_CMD ${CORE_SOURCES}/dot_hidden /.hidden

# Library search path
sed \
  's,^/usr/NextSpace,/usr/local/NextSpace,;/Libraries/s,^,/usr/local,'\
  ../../Core/os_files/etc/ld.so.conf.d/nextspace.conf\
  >> /usr/local/libdata/ldconfig/nextspace

# Preferences
$MKDIR_CMD $DEST_DIR/Library/Preferences
$CP_CMD ${CORE_SOURCES}/Library/Preferences/* $DEST_DIR/Library/Preferences/

# X11
$PRIV_CMD cat ${CORE_SOURCES}/etc/X11/Xresources.nextspace >> $DEST_DIR/etc/X11/xinit/.Xresources

ECHO "$(tput setaf 2 bold)"
ECHO "Creating various rcfiles, init scripts etc. Paths created/visited listed below:"
ECHO "$(tput sgr0)"

# PolKit & udev
if ! [ -d $DEST_DIR/etc/polkit-1/rules.d ];then
	$MKDIR_CMD -v $DEST_DIR/etc/polkit-1/rules.d
fi
$CP_CMD ${CORE_SOURCES}/etc/polkit-1/rules.d/*.rules $DEST_DIR/etc/polkit-1/rules.d/

#/usr/local/etc/devd for vendor additions in *.conf files per devd(8)
if ! [ -d $DEST_DIR/etc/devd/ ];then
  $MKDIR_CMD -v $DEST_DIR/etc/devd
fi
$CP_CMD ${CORE_SOURCES}/etc/devd/*.conf $DEST_DIR/etc/devd/

# User environment
if ! [ -d $DEST_DIR/etc/profile.d ];then
	$MKDIR_CMD -v $DEST_DIR/etc/profile.d
fi

# This should probably be sourced by users' .shrc files.
$CP_CMD ${CORE_SOURCES}/etc/profile.d/${IS_FREEBSD}nextspace.sh $DEST_DIR/etc/profile.d/nextspace.sh

# These need to be copied via `pw.useradd -k $DEST_DIR/etc/skel`
if ! [ -d $DEST_DIR/etc/skel ];then
	$MKDIR_CMD -v $DEST_DIR/etc/skel
fi
$CP_CMD ${CORE_SOURCES}/etc/skel/Library $DEST_DIR/etc/skel/

ECHO "Updating ${DEST_DIR}/etc/skel/Library/Preferences/.NextSpace/WM*.plist to root at $DEST_DIR"
sed -i -E 's|<string>/Applications/|<string>/usr/local/Applications/|' ${DEST_DIR}/etc/skel/Library/Preferences/.NextSpace/WM*.plist

$CP_CMD ${CORE_SOURCES}/etc/skel/.config $DEST_DIR/etc/skel/
$CP_CMD ${CORE_SOURCES}/etc/skel/.emacs.d $DEST_DIR/etc/skel/
$CP_CMD ${CORE_SOURCES}/etc/skel/.gtkrc-2.0 $DEST_DIR/etc/skel/
$CP_CMD ${CORE_SOURCES}/etc/skel/.*.nextspace $DEST_DIR/etc/skel/

# /root
$CP_CMD ${CORE_SOURCES}/etc/skel/.config /root
$CP_CMD ${CORE_SOURCES}/etc/skel/Library /root

ECHO "Updating /root/Library/Preferences/.NextSpace/WM*.plist to root at $DEST_DIR"
sed -i -E 's|<string>/Applications/|<string>/usr/local/Applications/|' /root/Library/Preferences/.NextSpace/WM*.plist

if ! [ -d $NEXTSPACE_HOME/bin ];then
  $MKDIR_CMD -v $NEXTSPACE_HOME/bin
fi
$CP_CMD ${CORE_SOURCES}/usr/NextSpace/bin/* $NEXTSPACE_HOME/bin/

# Icons, Plymouth resources and fontconfig configuration
if ! [ -d /usr/local/share ]; then
  $MKDIR_CMD -v /usr/local/share
fi
$CP_CMD ${CORE_SOURCES}/usr/share/* /usr/local/share/

# Add a nice baseline freetype font. It's handy in case you need bigger fonts.
# Accessibility is real, yo.
cat > ${DEST_DIR}/share/X11/xorg.conf.d/10-dejavu-fonts.conf << 'EOF'
Section "Files"
    FontPath "/usr/local/share/fonts/dejavu/"
EndSection
EOF

if [ "$DEST_DIR" = "" ]; then
  $PRIV_CMD ldconfig -R
fi

ECHO "$(tput setaf 3 bold)MANUAL INTERVENTION REQUIRED!"
ECHO "$(tput sgr0)"
ECHO "You might have ignored warnings from the installer, that's probably not wise. Small things here are bugs in Applications."
ECHO ""
ECHO "LOOK HERE NextStep on FreeBSD early adopters -- Steven"
ECHO ""
ECHO "0. You should probably source $DEST_DIR/etc/profile.d/nextspace.sh in your login shell file (.shrc, .bashrc, etc.)"
ECHO ""
ECHO "1. $DEST_DIR/etc/skel/Library (and thus /root/Library) contain VITAL plists with VITAL paths. This is important for debugging."
ECHO "You might want to keep these paths handy in the case of broken things."
ECHO ""
ECHO "2. Trying starting X. Check out xset -q to make sure fonts and so on are reasonable. Also /var/log/Xorg.0.log"
ECHO "$(tput setaf 3 bold)END TRANSMISSION"
ECHO "$(tput sgr0)"
