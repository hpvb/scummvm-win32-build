#!/bin/bash
set -e

export BASEPREFIX=${HOME}/scummvm-win32/libs
export BASEBUILDPREFIX=${HOME}/scummvm-win32/libs-build

export TOOLPREFIX=${HOME}/scummvm-win32/toolchain
export DOWNLOADPREFIX=${HOME}/scummvm-win32/dl
export PATCHPREFIX=$(dirname $0)/patches
export PATH=${TOOLPREFIX}/bin:${PATH}
OLDPATH=${PATH}

function unpack {
  if [ ! -d ${BUILDPREFIX}/src/${1} ]; then
    tar xf ${DOWNLOADPREFIX}/${1}*tar* -C ${BUILDPREFIX}/src
    if [ -e ${PATCHPREFIX}/${1}.patch ]; then
      pushd ${BUILDPREFIX}/src/${1}
      patch -p1 < ${PATCHPREFIX}/${1}.patch
      popd 
    fi
  fi
}

function autoreconf-package {
  pushd ${BUILDPREFIX}/src/${1}
  autoreconf -fi 
  popd
}

function autotools_build {
  pushd ${BUILDPREFIX}/src/${1}
  make clean || /bin/true
  ./configure --host=${HOST} --enable-shared --prefix=${PREFIX} ${2}
  make -j4
  make install
  popd
}

LIBZ=zlib-1.2.8
LIBICONV=libiconv-1.14
EXPAT=expat-2.2.0
PCRE=pcre-8.38
LIBPNG=libpng-1.6.26
LIBJPEG=libjpeg-turbo-1.5.1
LIBVORBIS=libvorbis-1.3.5
LIBOGG=libogg-1.3.2
LIBTHEORA=libtheora-1.1.1
LIBTHEORA_OPTIONS=--disable-examples
LIBFLAC=flac-1.3.1
LIBFREETYPE=freetype-2.7
LIBFAAD=faad2-2.7
LIBFAAD_AUTORECONF=true
LIBMAD=libmad-0.15.1b
LIBMAD_AUTORECONF=true
LIBSDL=SDL2-2.0.5
LIBMPEG2=libmpeg2-0.5.1
LIBMPEG2_OPTIONS=--disable-sdl
LIBMPEG2_AUTORECONF=true
LIBFFI=libffi-3.2.1
GETTEXT=gettext-0.19.8.1
GETTEXT_OPTIONS="--disable-java --disable-native-java --enable-threads=win32 --enable-static --disable-openmp --without-cvs --without-git"
GETTEXT_AUTORECONF=true
GLIB2=glib-2.51.0
GLIB2_AUTORECONF=true
GLIB2_OPTIONS="--disable-silent-rules --disable-compile-warnings"
GLIB2_STATIC=${GLIB2}
GLIB2_STATIC_AUTORECONF=true
GLIB2_STATIC_OPTIONS="${GLIB2_OPTIONS} --disable-shared --enable-static"
FLUIDSYNTH=fluidsynth-1.1.6

for ARCH in 32 64; do
  PREFIX=${BASEPREFIX}/${ARCH}
  BUILDPREFIX=${BASEBUILDPREFIX}/${ARCH}
  export PATH=${PREFIX}/bin:${OLDPATH}
  export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

  if [ $ARCH == 32 ]; then
    HOST=i686-w64-mingw32
  else
    HOST=x86_64-w64-mingw32
  fi

  export CC=${HOST}-gcc
  export CXX=${HOST}-g++
  export LD=${HOST}-ld
  export AR=${HOST}-ar
  export WINDRES=${HOST}-windres
  export RANLIB=${HOST}-ranlib

  export CFLAGS="-m${ARCH} -O3"
  export CPPFLAGS="-I${PREFIX}/include"
  export CXXFLAGS="${CFLAGS}"
  export LDFLAGS="-m${ARCH} -L${PREFIX}/lib"

  mkdir -p ${PREFIX}/stamps
  mkdir -p ${PREFIX}/lib
  if [ ! -e ${PREFIX}/lib${ARCH} ]; then
    ln -s lib ${PREFIX}/lib${ARCH}
  fi
  mkdir -p ${BUILDPREFIX}/src

  if [ ! -e ${PREFIX}/stamps/LIBZ-${LIBZ} ]; then
    unpack ${LIBZ}

    pushd ${BUILDPREFIX}/src/${LIBZ}
    make -f win32/Makefile.gcc clean || /bin/true

    make -f win32/Makefile.gcc PREFIX=${HOST}- CFLAGS="${CFLAGS}" LDFLAGS="-m${ARCH}" 
    make -f win32/Makefile.gcc PREFIX=${HOST}- INCLUDE_PATH=${PREFIX}/include/ LIBRARY_PATH=${PREFIX}/lib BINARY_PATH=${PREFIX}/bin SHARED_MODE=1 install

    touch ${PREFIX}/stamps/LIBZ-${LIBZ}
    popd
  fi

  for LIBNAME in LIBICONV EXPAT PCRE LIBFFI GETTEXT GLIB2 GLIB2_STATIC LIBPNG LIBJPEG LIBOGG LIBVORBIS LIBFLAC LIBFAAD LIBTHEORA LIBFREETYPE LIBSDL LIBMAD LIBMPEG2 FLUIDSYNTH; do
    eval LIB=\$${LIBNAME}
    eval AUTORECONF=\$${LIBNAME}_AUTORECONF

    if [ ! -e ${PREFIX}/stamps/${LIBNAME}-${LIB} ]; then
      unpack ${LIB}

      if [ "${AUTORECONF}" == "true" ]; then
        autoreconf-package ${LIB}
      fi

      eval autotools_build ${LIB} \"\$${LIBNAME}_OPTIONS\"

      touch ${PREFIX}/stamps/${LIBNAME}-${LIB}
    fi
  done
done
