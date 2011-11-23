#!/bin/bash

#  Automatic build script for libssh2 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 02.02.11.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here
#
VERSION="1.2.8"
SDKVERSION="5.0"
#
###########################################################################
#
# Don't change anything here
CURRENTPATH=`pwd`
ARCHS="i386 armv7"

##########
set -e
if [ ! -e libssh2-${VERSION}.tar.gz ]; then
	echo "Downloading libssh2-${VERSION}.tar.gz"
    curl -O http://www.libssh2.org/download/libssh2-${VERSION}.tar.gz
else
	echo "Using libssh2-${VERSION}.tar.gz"
fi

mkdir -p src

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
		CFLAGS="-mmacosx-version-min=10.7"
	else
		PLATFORM="iPhoneOS"
		CFLAGS="-miphoneos-version-min=5.0"
	fi
	echo "Building libssh2 for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."
  tar zxf libssh2-${VERSION}.tar.gz -C src
	cd src/libssh2-${VERSION}

	export DEVROOT="/Developer/Platforms/${PLATFORM}.platform/Developer"
	export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
  export CC=$DEVROOT/usr/bin/clang
  export BUILD_CC=$DEVROOT/usr/bin/clang
  export BUILD_CXX=$DEVROOT/usr/bin/clang
  export LD=$DEVROOT/usr/bin/ld
  export CPP="$DEVROOT/usr/bin/clang -E"
  export CXX=$DEVROOT/usr/bin/clang
  export AR=$DEVROOT/usr/bin/ar
  export AS=$DEVROOT/usr/bin/as
  export NM=$DEVROOT/usr/bin/nm
  export CXXCPP="$DEVROOT/usr/bin/clang -E"
	export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} $CFLAGS"

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-libssh2-${VERSION}.log"
	
  ./configure --host=${ARCH}-apple-darwin --prefix="${SDKROOT}/usr" -with-openssl --with-libssl-prefix="${SDKROOT}/usr" --disable-shared --enable-static >> "${LOG}" 2>&1
	
	make >> "${LOG}" 2>&1
	echo "Installing into ${SDKROOT}/usr"
	sudo make install >> "${LOG}" 2>&1
	echo "Installed"
	cd ${CURRENTPATH}
	rm -rf src/libssh2-${VERSION}
	
done

echo "Building done."