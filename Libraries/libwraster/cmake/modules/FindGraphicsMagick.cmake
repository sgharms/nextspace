#
# Find the GraphicsMagick includes and library
# Got from https://github.com/darktable-org/darktable/tree/master/cmake/modules
#

# This module defines
# GraphicsMagick_VERSION
# GraphicsMagick_INCLUDE_DIRS, where to find *.h etc
# GraphicsMagick_LIBRARIES, the libraries
# GraphicsMagick_FOUND, If false, do not try to use LCMS.


include(LibFindMacros)

# Use pkg-config to get hints about paths
libfind_pkg_check_modules(GraphicsMagick_PKGCONF GraphicsMagick)

# Include dir
find_path(GraphicsMagick_INCLUDE_DIR
  NAMES magick/api.h
  HINTS ${GraphicsMagick_PKGCONF_INCLUDE_DIRS}
  PATH_SUFFIXES GraphicsMagick
)

message(DEBUG, "Include-DIRS: ${GraphicsMagick_PKGCONF_INCLUDE_DIRS}")
message(DEBUG, "Include-DIR: ${GraphicsMagick_INCLUDE_DIR}")

# Finally the library itself
find_library(GraphicsMagick_LIBRARY
  NAMES GraphicsMagick
  HINTS ${GraphicsMagick_PKGCONF_LIBRARY_DIRS}
)

message(DEBUG, "Library-DIRS: ${GraphicsMagick_PKGCONF_LIBRARY_DIRS}")
message(DEBUG, "Library-DIR: ${GraphicsMagick_LIBRARY}")

if(GraphicsMagick_PKGCONF_VERSION)
  set(GraphicsMagick_VERSION ${GraphicsMagick_PKGCONF_VERSION})
endif()

set(GraphicsMagick_PROCESS_INCLUDES ${GraphicsMagick_INCLUDE_DIR})
set(GraphicsMagick_PROCESS_LIBS GraphicsMagick)
