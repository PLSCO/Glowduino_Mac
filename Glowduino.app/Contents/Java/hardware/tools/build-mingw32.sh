#!/bin/sh

set -e

BUILD_DIR=/tmp/mingw
MINGW_VERSION=i586-mingw32msvc

[ -d $BUILD_DIR ] || mkdir -p $BUILD_DIR
cd $BUILD_DIR

# get libusb sources
[ -d libusb-1.0.9 ] || { wget -O libusb-1.0.9.tar.bz2 http://sourceforge.net/projects/libusb/files/libusb-1.0/libusb-1.0.9/libusb-1.0.9.tar.bz2/download ; tar jxvf libusb-1.0.9.tar.bz2 ;}
cd libusb-1.0.9
PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig ./configure --host=$MINGW_VERSION --prefix=$BUILD_DIR
make
make install
cd ..

# get dfu-util sources
[ -d dfu-util ] || { wget http://dfu-util.gnumonks.org/releases/dfu-util-0.6.tar.gz ; tar zxvf dfu-util-0.6.tar.gz ;}
cd dfu-util-0.6
PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig ./configure --host=$MINGW_VERSION --prefix=$BUILD_DIR
make
make install
cd ..
