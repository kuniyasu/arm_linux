#!/bin/bash

PREFIX=$PWD
TARGET=arm-unknown-linux-gnueabihf

BINUTILS_VER=2.25
BINUTILS_FILE=binutils-$BINUTILS_VER

PATH=/home/arm_cross_tools/bin:$PATH

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

download_file
install_binutils
