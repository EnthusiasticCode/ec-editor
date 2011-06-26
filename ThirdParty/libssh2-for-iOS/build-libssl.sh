#!/bin/bash

#  Automatic build script for libssl and libcrypto 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 01.02.11.
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
#  Change values here													  #
#																		  #
VERSION="1.0.0d"													      #
SDKVERSION="5.0"														  #
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################

CURRENTPATH=`pwd`
ARCHS="i386 armv7"

set -e
if [ ! -e openssl-${VERSION}.tar.gz ]; then
	echo "Downloading openssl-${VERSION}.tar.gz"
    curl -O http://www.openssl.org/source/openssl-${VERSION}.tar.gz
else
	echo "Using openssl-${VERSION}.tar.gz"
fi

mkdir -p "${CURRENTPATH}/src"

tar zxf openssl-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/openssl-${VERSION}"


for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
	else
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
		PLATFORM="iPhoneOS"
	fi
	
	echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."

	export CC="/Developer/Platforms/${PLATFORM}.platform/Developer/usr/bin/gcc -arch ${ARCH}"
	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-openssl-${VERSION}.log"

	./Configure BSD-generic32 --openssldir="/Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk/usr" > "${LOG}" 2>&1
	# add -isysroot to CC=
	sed -ie "s!^CFLAG=!CFLAG=-isysroot /Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk !" "Makefile"

	make >> "${LOG}" 2>&1
	echo "Installing into /Developer/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk/usr"
	sudo make install >> "${LOG}" 2>&1
	echo "Installed"
	make clean >> "${LOG}" 2>&1
done

echo "Building done."
echo "Cleaning up..."
rm -rf ${CURRENTPATH}/src/openssl-${VERSION}
echo "Done."