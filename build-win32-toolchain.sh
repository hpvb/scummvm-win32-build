#!/bin/bash
set -e

export PREFIX=${HOME}/scummvm-win32/toolchain
export DOWNLOADPREFIX=${HOME}/scummvm-win32/dl
export BUILDPREFIX=${HOME}/scummvm-win32/toolchain-build
export PATH=${PREFIX}/bin:${PATH}

BINUTILS=binutils-2.27
GCC=gcc-6.2.0
MINGW64=mingw-w64-v5.0.0
NASM=nasm-2.12.02

mkdir -p ${PREFIX}/stamps
mkdir -p ${BUILDPREFIX}/src

for tool in ${BINUTILS} ${GCC} ${MINGW64} ${NASM}; do
  if [ ! -d ${BUILDPREFIX}/src/${tool} ]; then
    tar xf ${DOWNLOADPREFIX}/${tool}* -C ${BUILDPREFIX}/src
  fi
done

if [ ! -e ${PREFIX}/stamps/${BINUTILS} ]; then
  mkdir -p ${BUILDPREFIX}/${BINUTILS}
  pushd ${BUILDPREFIX}/${BINUTILS}
  make clean || /bin/true

  ${BUILDPREFIX}/src/${BINUTILS}/configure --target=x86_64-w64-mingw32 --enable-targets=x86_64-w64-mingw32,i686-w64-mingw32 --with-sysroot=${PREFIX} --prefix=${PREFIX}
  make -j4 
  make install
  touch ${PREFIX}/stamps/${BINUTILS} 
  popd
fi

if [ ! -e ${PREFIX}/stamps/${MINGW64}-headers ]; then
  mkdir -p ${BUILDPREFIX}/${MINGW64}-headers
  pushd ${BUILDPREFIX}/${MINGW64}-headers
  make clean || /bin/true

  ${BUILDPREFIX}/src/${MINGW64}/mingw-w64-headers/configure --host=x86_64-w64-mingw32 --prefix=${PREFIX}/mingw
  make -j4 
  make install
  touch ${PREFIX}/stamps/${MINGW64}-headers 
  popd
fi

if [ ! -e ${PREFIX}/stamps/${GCC}-core ]; then
  if [ ! -e ${BUILDPREFIX}/src/${GCC}/gmp ]; then
    pushd ${BUILDPREFIX}/src/${GCC}
    ${BUILDPREFIX}/src/${GCC}/contrib/download_prerequisites
    popd 
  fi

  mkdir -p ${BUILDPREFIX}/${GCC}
  pushd ${BUILDPREFIX}/${GCC}
  make clean || /bin/true

  ${BUILDPREFIX}/src/${GCC}/configure --enable-languages=c,c++ --target=x86_64-w64-mingw32 --enable-targets=all --with-sysroot=${PREFIX} --prefix=${PREFIX}
  make -j4 all-gcc
  make install-gcc
  touch ${PREFIX}/stamps/${GCC}-core
  popd
fi

if [ ! -e ${PREFIX}/stamps/${MINGW64}-crt ]; then
  mkdir -p ${BUILDPREFIX}/${MINGW64}-crt
  pushd ${BUILDPREFIX}/${MINGW64}-crt
  make clean || /bin/true

  ${BUILDPREFIX}/src/${MINGW64}/mingw-w64-crt/configure --enable-lib32 --host=x86_64-w64-mingw32 --with-sysroot=${PREFIX} --prefix=${PREFIX}/mingw
  make -j4 
  make install
  touch ${PREFIX}/stamps/${MINGW64}-crt
  popd
fi

if [ ! -e ${PREFIX}/stamps/${GCC} ]; then
  pushd ${BUILDPREFIX}/${GCC}

  make -j4
  make install
  touch ${PREFIX}/stamps/${GCC}
  popd
fi

if [ ! -e ${PREFIX}/stamps/${NASM} ]; then
  mkdir -p ${BUILDPREFIX}/${NASM}
  pushd ${BUILDPREFIX}/${NASM}
  make clean || /bin/true

  ${BUILDPREFIX}/src/${NASM}/configure --enable-lib32 --target=x86_64-w64-mingw32 --with-sysroot=${PREFIX} --prefix=${PREFIX}
  make -j4 
  make install
  touch ${PREFIX}/stamps/${NASM}
  popd
fi

pushd ${PREFIX}/bin
for tool in x86_64-w64-mingw32*; do
  i686_tool=${tool/x86_64/i686}
  if [ ! -e ${i686_tool} ]; then
    ln -s $tool $i686_tool
  fi
done

rm i686-w64-mingw32-windres
echo -e 'x86_64-w64-mingw32-windres --target=pe-i386 $@' > i686-w64-mingw32-windres
chmod +x i686-w64-mingw32-windres

