#!/bin/bash

PREFIX=$PWD
TARGET=arm-unknown-linux-gnueabihf
MAKE_OPT=-j8
LINUX_DEFCONFIG=socfpga_defconfig

BINUTILS_VER=2.25
BINUTILS_FILE=binutils-$BINUTILS_VER

LINUX_VER=4.1.6
LINUX_FILE=linux-$LINUX_VER

GLIBC_VER=2.22
GLIBC_FILE=glibc-$GLIBC_VER

GCC_VER=5.2.0
GCC_FILE=gcc-$GCC_VER

PATH=/home/arm_cross_tools/bin:$PATH
#LD_LIBRARY_PATH=$PREFIX/usr/lib:$LD_LIBRARY_PATH

FP_OPT="--with-fp --with-float=hard --with-fpu=neon-vfpv4 --with-mode=thumb --with-arch=armv7-a "

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
  download https://www.kernel.org/pub/linux/kernel/v4.x/ $LINUX_FILE.tar.gz
  download http://ftp.gnu.org/gnu/glibc $GLIBC_FILE.tar.gz

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
    --target=$TARGET \
    --with-lib-path=$PREFIX/usr/lib \
    --with-sysroot

    make
    make install

#    make -C ld clean
#    make -C ld LIB_PATH=/usr/lib:/lib
#    cp -v ld/ld-new $PREFIX/usr/bin

  cd ..
  cd $PREFIX

  ln -s usr/lib lib
  ln -s usr/sbin sbin
}

install_linux_kernel(){
  if [ ! -d build ]; then
    mkdir build
  fi

  cd build

  tar zxf ../download/$LINUX_FILE.tar.gz

  cd $LINUX_FILE
    make mrproper
    make ARCH=arm $LINUX_DEFCONFIG
    make ARCH=arm headers_check
    make ARCH=arm INSTALL_HDR_PATH=$PREFIX/usr headers_install
  cd ..

  cd ..
}

install_glibc(){
  create_build_dir $GLIBC_FILE

  cd build

    tar zxf ../download/$GLIBC_FILE.tar.gz

    cd build-$GLIBC_FILE

    CC=$TARGET-gcc \
    CXX=$TARGET-g++ \
    AR=$TARGET-ar \
    LD=$TARGET-g++ \
    RANLIB=$TARGET-ranlib \
    ../$GLIBC_FILE/configure \
    --prefix=/usr \
    --host=$TARGET \
    --target=$TARGET \
    --with-headers=$PREFIX/usr/include \
    --enable-kernel=2.6.25 \
    libc_cv_forced_unwind=yes \
    libc_cv_ctors_header=yes \
    libc_cv_c_cleanup=yes \
    $FP_OPT

    make
    make install install_root=$PREFIX
    cd ..
  cd ..
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
    AS=$TARGET-as \
    AR=$TARGET-ar \
    LD=$TARGET-g++ \
    RANLIB=$TARGET-ranlib \
    ../$GCC_FILE/configure \
    --prefix=$PREFIX/usr \
    --with-local-prefix=$PREFIX/usr \
    --host=$TARGET \
    --target=$TARGET \
    --with-native-system-header-dir=$PREFIX/usr/include \
    --enable-languages=c \
    --disable-libstdcxx-pch \
    --disable-multilib \
    --disable-bootstrap \
    $FP_OPT

    make $MAKE_OPT

    make install
  cd ..

  cd ..
}

download_file
install_binutils
install_linux_kernel
install_glibc
LD_LIBRARY_PATH=$PREFIX/usr/lib:$LD_LIBRARY_PATH
install_gcc
