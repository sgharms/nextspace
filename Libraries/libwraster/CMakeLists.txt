cmake_minimum_required(VERSION 3.15)

project(libwraster
  VERSION 7.0.1
  LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# source directory is a cmake subdir - TODO
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules/")

include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckSymbolExists)
find_package(PkgConfig QUIET)

# Add FreeBSD-specific include paths for header detection
list(APPEND CMAKE_REQUIRED_INCLUDES 
  "/usr/local/include"
  "/usr/include"
  "/usr/local/include/X11"
)

# Also respect CMAKE_INCLUDE_PATH environment variable
if(DEFINED ENV{CMAKE_INCLUDE_PATH})
  string(REPLACE ":" ";" CMAKE_INCLUDE_PATH_LIST "$ENV{CMAKE_INCLUDE_PATH}")
  list(APPEND CMAKE_REQUIRED_INCLUDES ${CMAKE_INCLUDE_PATH_LIST})
endif()

# FreeBSD-specific library paths
list(APPEND CMAKE_PREFIX_PATH 
  "/usr/local"
  "/usr"
)

# FreeBSD-specific library search paths
link_directories("/usr/local/lib")

# Debug: Print the include paths being used
message(STATUS "CMAKE_REQUIRED_INCLUDES: ${CMAKE_REQUIRED_INCLUDES}")
message(STATUS "CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")
message(STATUS "Environment CMAKE_INCLUDE_PATH: $ENV{CMAKE_INCLUDE_PATH}")

check_include_files("math.h" HAVE_MATH_H)
if (HAVE_MATH_H)
  set(CMAKE_REQUIRED_LIBRARIES "-lm")
  check_function_exists(atan HAVE_ATAN)
  check_function_exists(sqrt HAVE_SQRT)
  check_function_exists(cosf HAVE_COSF)
  check_function_exists(sinf HAVE_SINF)
  check_function_exists(powf HAVE_POWF)
  if (HAVE_ATAN AND HAVE_SQRT AND HAVE_COSF AND HAVE_SINF AND HAVE_POWF)
    set(HAVE_FLOAT_MATHFUNC 1)
  endif()
  check_symbol_exists(M_PI "math.h" HAVE_M_PI)
  if (HAVE_M_PI)
    set(WM_PI 1)
    set(M_PI_VALUE "(M_PI)")
  endif()
endif()

check_include_files("stdnoreturn.h" HAVE_STDNORETURN)

# JPEG support
check_include_files("stdio.h;jpeglib.h" USE_JPEG)

find_package(GraphicsMagick COMPONENTS MagickWand)
if (GraphicsMagick_FOUND)
  set(USE_MAGICK 1)
  set(MAGICK_INCLUDES -I${GraphicsMagick_INCLUDE_DIRS})
  # Use standard GraphicsMagick library names instead of full paths
  set(MAGICK_LIBS -lGraphicsMagick)
  
  message(STATUS "GraphicsMagick include: ${GraphicsMagick_INCLUDE_DIRS}")
  message(STATUS "GraphicsMagick library: ${GraphicsMagick_LIBRARIES}")
endif()

# PNG support
check_include_files("png.h" USE_PNG)

# GIF support  
check_include_files("gif_lib.h" HAVE_GIF)
if (HAVE_GIF)
  set(CMAKE_REQUIRED_LIBRARIES "-lgif")
  check_function_exists(DGifOpenFileName USE_GIF)
endif()

# TIFF support
set(CMAKE_REQUIRED_LIBRARIES "-L/usr/local/lib -ltiff")
check_include_files("tiff.h;tiffio.h" HAVE_TIFF)
if (HAVE_TIFF)
  check_function_exists(TIFFOpen USE_TIFF)
endif()

# WebP support
set(CMAKE_REQUIRED_LIBRARIES "-L/usr/local/lib -lwebp")  
check_include_files("webp/decode.h" USE_WEBP)

# X11 shared memory support
set(CMAKE_REQUIRED_LIBRARIES "-L/usr/local/lib -lX11")
check_include_files("X11/Xlib.h" HAVE_X11_BASE)
if(HAVE_X11_BASE)
  set(CMAKE_REQUIRED_LIBRARIES "-L/usr/local/lib -lX11 -lXext")
  check_include_files("X11/Xlib.h;X11/extensions/XShm.h" HAVE_XSHM)
  if (HAVE_XSHM)
    check_function_exists(XShmAttach USE_XSHM)
  endif()
else()
  message(STATUS "X11/Xlib.h not found - X11 support disabled")
  set(HAVE_XSHM 0)
  set(USE_XSHM 0)
endif()

# XPM support
set(CMAKE_REQUIRED_LIBRARIES "-L/usr/local/lib -lX11 -lXpm")
check_include_files("X11/xpm.h" USE_XPM)

configure_file(cmake/config.h.in ../config.h)
configure_file(cmake/GNUmakefile.config.in ../GNUmakefile.config @ONLY)
