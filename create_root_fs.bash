#!/bin/bash

PREFIX=$PWD
TARGET=arm-unknown-linux-gnueabihf
MAKE_OPT=-j8

BINUTILS_VER=2.25
BINUTILS_FILE=binutils-$BINUTILS_VER

LINUX_VER=4.1.6
LINUX_FILE=linux-$LINUX_VER

GLIBC_VER=2.26
GLIBC_FILE=glibc-$GLIBC_VER

GCC_VER=5.2.0
GCC_FILE=gcc-$GCC_VER

PATH=/home/arm_cross_tools/bin:$PATH
LD_LIBRARY_PATH=$PREFIX/usr/lib:$LD_LIBRARY_PATH

function download(){
  if [ ! -f $2 ]; then
    wget $1/$2
  fi
}

function create_build_dir(){
  if [ ! -d $PREFIX/build ]; then
    mkdir $PREFIX/build
  fi

  cd $PREFIX/build

  if [ -d $1 ]; then
    rm -rf $1
  fi

  if [ -d build-$1 ]; then
    rm -rf build-$1
  fi

  mkdir build-$1

  cd ..
}

function download_file(){
  if [ ! -d download ]; then
    mkdir download
  fi

  cd download

  download http://ftp.gnu.org/gnu/binutils $BINUTILS_FILE.tar.gz
  download http://ftp.gnu.org/gnu/gcc/$GCC_FILE $GCC_FILE.tar.gz
  download_file https://www.kernel.org/pub/linux/kernel/v4.x/ $LINUX_FILE.tar.gz
  download_file http://ftp.gnu.org/gnu/glibc/ $GLIBC_FILE.tar.gz

  cd ..
}

function install_binutils(){
  create_build_dir $BINUTILS_FILE

  cd build
  tar zxf ../download/$BINUTILS_FILE.tar.gz

  cd build-$BINUTILS_FILE

    CC=$TARGET-gcc \
    CXX=$TARGET-g++ \
    AR=$TARGET-ar \
    LD=$TARGET-g++ \
    RANLIB=$TARGET-ranlib \
    ../$BINUTILS_FILE/configure \
    --prefix=$PREFIX/usr \
    --host=$TARGET \
    --with-lib-path=$PREFIX/usr/lib \
    --with-sysroot

    make
    make install

    make -C ld clean
    make -C ld LIB_PATH=/usr/lib:/lib
    cp -v ld/ld-new $PREFIX/usr/bin

  cd ..
  cd $PREFIX
}

function install_gcc(){
  create_build_dir $GCC_FILE

  cd build

  tar zxf ../download/$GCC_FILE.tar.gz
  cd $GCC_FILE
    ./contrib/download_prerequisites
  cd ..

  cd build-$GCC_FILE

    CC=$TARGET-gcc \
    CXX=$TARGET-g++ \
    AR=$TARGET-ar \
    LD=$TARGET-g++ \
    RANLIB=$TARGET-ranlib \
    ../$GCC_FILE/configure \
    --prefix=$PREFIX/usr \
    --with-local-prefix=$PREFIX/usr \
    --host=$TARGET \
    --with-native-system-header-dir=$PREFIX/usr/include \
    --enable-languages=c,c++ \
    --disable-libstdcxx-pch \
    --disable-multilib \
    --disable-bootstrap

    make $MAKE_OPT

    make install
  cd ..

  cd ..
}

download_file
install_binutils
install_gcc
