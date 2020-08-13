#!/bin/bash

set -x

# Usage:  ./build_tor.sh <platform>  <android_ver> <compile_arh> <EABI> <ABI>
# Example ./build_tor.sh i686-linux-android  19 i686 x86 x86
#         ./build_tor.sh arm-linux-androideabi  19 arm7 arm-linux-androideabi arm
#         ./build_tor.sh aarch64-linux-android  21 armv8 aarch64-linux-android arm64

# NOTE:  OpenSSL  will be build with NDK 17.   But evebts and Tor - with tools chanins from NDK 21.
#       It is done intentionally because OpenSSL config script doesn't worj with a modern NDK.
#       But Tor require modern compiler, so it will not work with the 17-th version

export WORK_DIR=`pwd`
#export ANDROID_NDK_HOME=$WORK_DIR/ndk_17_2_4988734
export ANDROID_NDK_HOME=$WORK_DIR/ndk_21_1_6352462
export PLATFORM=$1
export ANDROID_VER=$2
export COMPILE_ARCH=$3
export ANDROID_EABI=$4
export ANDROID_ARCH=$5

export TOR_BRANCH="release-0.4.4"

export JOBS=16

# -----------------------------------------------------------------

ORIGIN_PATH=$PATH

# Let's make a standalone toolchain
export ANDROID_TOOLCHAIN="$WORK_DIR/ndk_${ANDROID_VER}_${ANDROID_ARCH}"
export TOOLCHAIN_PATH=$ANDROID_TOOLCHAIN/bin
rm -rf $ANDROID_TOOLCHAIN
$ANDROID_NDK_HOME/build/tools/make-standalone-toolchain.sh --platform=android-$ANDROID_VER --arch=$ANDROID_ARCH --install-dir=$ANDROID_TOOLCHAIN

# Requed for OpenSSL   See  details at NOTES.ANDROID
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_HOME/toolchains/$ANDROID_EABI-4.9/prebuilt/linux-x86_64/bin:$PATH

NATIVE_DIR="native_$PLATFORM"
OPEN_SSL_LOCATION="$WORK_DIR/$NATIVE_DIR/openssl-$PLATFORM"

rm -Rf $NATIVE_DIR
mkdir $NATIVE_DIR
mkdir $NATIVE_DIR/lib
mkdir $NATIVE_DIR/include

cd $NATIVE_DIR

#if false; then

# BUILD openssl1.1.0f
echo "BUILD OPENSSL"

rm openssl-1.1.1g.tar.*
wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1g.tar.gz
rm -rf openssl-1.1.1g
tar -xvzf openssl-1.1.1g.tar.gz

rm -rf $OPEN_SSL_LOCATION

cd openssl-1.1.1g

#./config shared no-ssl2 no-ssl3 no-comp no-hw no-engine --openssldir=$OPEN_SSL_LOCATION  --prefix=$OPEN_SSL_LOCATION
./Configure android-$ANDROID_ARCH -D__ANDROID_API__=$ANDROID_VER --openssldir=$OPEN_SSL_LOCATION  --prefix=$OPEN_SSL_LOCATION no-hw

make -j${JOBS} depend
make -j${JOBS} all

#sudo -E make install CC=$ANDROID_TOOLCHAIN/$PLATFORM-gcc RANLIB=$ANDROID_TOOLCHAIN/$PLATFORM-ranlib
make install CC=$TOOLCHAIN_PATH/$PLATFORM-gcc RANLIB=$TOOLCHAIN_PATH/$PLATFORM-ranlib

cd ..

#fi

# Toolchain is NDK 21
# setup c/c++ compiler
export TOOL=$PLATFORM
export ANDROID_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}/${TOOL}
export CC="$ANDROID_TOOLCHAIN_BASENAME-gcc -D__ANDROID_API__=$ANDROID_VER "
export CXX="$ANDROID_TOOLCHAIN_BASENAME-g++ -D__ANDROID_API__=$ANDROID_VER "
export LINK=${CXX}
export LD=$ANDROID_TOOLCHAIN_BASENAME-ld
export AR=$ANDROID_TOOLCHAIN_BASENAME-ar
export AS=$ANDROID_TOOLCHAIN_BASENAME-as
export NM=$ANDROID_TOOLCHAIN_BASENAME-nm
export RANLIB=$ANDROID_TOOLCHAIN_BASENAME-ranlib
export STRIP=$ANDROID_TOOLCHAIN_BASENAME-strip
export OBJDUMP=$ANDROID_TOOLCHAIN_BASENAME-objdump
export ARCH_FLAGS="-march=$COMPILE_ARCH "
export ARCH_LINK="-march=$COMPILE_ARCH"
export CPPFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing"
export CXXFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -frtti -fexceptions "
export CFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing "

export PATH="$ANDROID_TOOLCHAIN/bin/:$ORIGIN_PATH"
export HOST=$PLATFORM

#if false; then

echo "BUILD libevent"
rm -Rf libevent

git clone https://github.com/marcotessarotto/libevent
cd libevent

./autogen.sh

./configure --host=$PLATFORM

make -j${JOBS}

cp .libs/libevent.a ../lib
cp -R include/* ../include
cd ..

#fi

#Build Tor
echo "BUILD TOR"
git clone https://github.com/torproject/tor
cd tor/

git checkout -b tobuild  origin/$TOR_BRANCH

export CPPFLAGS=" ${CPPFLAGS} --sysroot=$ANDROID_TOOLCHAIN/sysroot -I$ANDROID_TOOLCHAIN/sysroot/usr/include -I$ANDROID_TOOLCHAIN/include -I../include -I../include/event2"
export LDFLAGS=" ${ARCH_LINK} -L$ANDROID_TOOLCHAIN/sysroot/usr/lib -L$ANDROID_TOOLCHAIN/lib -L../lib"

./autogen.sh
./configure --host=$PLATFORM --disable-tool-name-check --disable-asciidoc --disable-lzma --disable-zstd --prefix=$ANDROID_TOOLCHAIN --with-openssl-dir=$OPEN_SSL_LOCATION --enable-static-openssl --with-libevent-dir=../lib --enable-static-libevent  --disable-silent-rules

make -j${JOBS}

#tests fail on compilation, but tor is built (in src/or/tor)

cd ..

