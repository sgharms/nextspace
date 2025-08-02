# FreeBSD Config

BUILD_TOOLS="
    cmake
    git
    gmake
    ninja
    pkgconf
"
#--- libdispatch, libcorefoundation, libobjc2
RUNTIME_DEPS="
ftp/curl \
devel/icu \
misc/libuuid \
textproc/libxml2 \
archivers/zstd \
avahi-libdns
"
#--- Patches required to update the source to compile. Taken from the Swift 5.10 package
LIBDISPATCH_PATCHES="
    patch-swift-corelibs-libdispatch_src_shims_lock.c \
    patch-swift-corelibs-libdispatch_src_shims_lock.h \
    patch-swift-corelibs-libdispatch_src_queue.c \
    patch-swift-corelibs-libdispatch_src_apply.c \
    patch-swift-corelibs-libdispatch_src_data.c \
    patch-swift-corelibs-libdispatch_src_init.c \
    patch-swift-corelibs-libdispatch_src_io.c \
    patch-swift-corelibs-libdispatch_src_event_event__config.h \
    patch-swift-corelibs-libdispatch_src_event_event__kevent.c \
    patch-swift-corelibs-libdispatch_src_event_workqueue.c \
    patch-swift-corelibs-libdispatch_src_event_workqueue__internal.h
"

LIBCOREFOUNDATION_PATCHES="
  patch-swift-corelibs-foundation_CoreFoundation_Base.subproj_CFPlatform.c \
  patch-swift-corelibs-foundation_CoreFoundation_Base.subproj_CoreFoundation__Prefix.h \
  patch-swift-corelibs-foundation_CoreFoundation_NumberDate.subproj_CFDate.c \
  patch-swift-corelibs-foundation_CoreFoundation_PlugIn.subproj_CFBundle__Internal.h \
  patch-swift-corelibs-foundation_CoreFoundation_RunLoop.subproj_CFRunLoop.c
"

#--- gnustep-make
GNUSTEP_MAKE_DEPS="
    zsh
"
RUNTIME_RUN_DEPS="
    libbsd0
    libuuid1
    libcurl4
    libcurl3-gnutls
    libavahi-compat-libdnssd1
    zsh
"
#--- libwraster
WRASTER_DEPS="
  GraphicsMagick
"
WRASTER_RUN_DEPS="
    libgif7
    libjpeg8
    libtiff5
    libpng16-16
    libwebp7
    libxpm4
    libxmu6
    libxext6
    libx11-6 
"
#--- gnustep-base
GNUSTEP_BASE_DEPS="
    libffi-dev
    libxml2-dev
    libxslt1-dev
    libavahi-client-dev
    libcups2-dev
    libgnutls28-dev
"
GNUSTEP_BASE_RUN_DEPS="
    libffi8
    libavahi-client3
    libxml2
    libxslt1.1
    libicu70
    libicu-dev
    libgnutls30
    libcups2
"
#--- gnustep-gui
GNUSTEP_GUI_DEPS="
    libao-dev
    libsndfile1-dev
"
GNUSTEP_GUI_RUN_DEPS="
    libao4
    libsndfile1
"
#--- back-art
BACK_ART_DEPS="
    libart-2.0-dev
    libfreetype-dev
    libxcursor-dev
    libxfixes-dev
    libxt-dev
    libxrandr-dev
"
BACK_ART_RUN_DEPS="
    libart-2.0-2
    libfreetype6
    libxcursor1
    libxfixes3
    libxt6
    libxrandr2
"
#--- Frameworks
FRAMEWORKS_BUILD_DEPS="
    libmagic-dev
    libudisks2-dev
    libdbus-1-dev
    libupower-glib-dev
    libxkbfile-dev
    libxcursor-dev
    libxrandr-dev
    libpulse-dev
"
FRAMEWORKS_RUN_DEPS="
    libmagic1
    libglib2.0-0
    dbus
    libdbus-1-3
    udisks2
    libudisks2-0
    libupower-glib3
    libxkbfile1
    libxrandr2
    pulseaudio
    libpulse0
    upower
"
#--- Applications
APPS_BUILD_DEPS="
    libfontconfig-dev
    libxft-dev
    libxinerama-dev
    libxcomposite-dev
    libxrender-dev
    libxdamage-dev
    libexif-dev
    libpam0g-dev
"
APPS_RUN_DEPS="
    fontconfig
    libfontconfig1
    libxft2
    libxinerama1
    libxcomposite1
    libxrender1
    libxdamage1
    libexif12
    xserver-xorg-core
    xserver-xorg-input-evdev
    xserver-xorg-input-synaptics
    xfonts-100dpi
    xserver-xorg-video-vmware
    xserver-xorg-video-intel
    x11-xkb-utils
    x11-xserver-utils
"
#    libpam0g 
#xserver-xorg-input-kbd
#xserver-xorg-input-mouse
