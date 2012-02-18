LOG="build.log"
PLATFORMS_ROOT="/Applications/Xcode.app/Contents/Developer/Platforms/"
ARCHS="i386 armv7"
SDKVERSION="5.0"
OSXSDKVERSION="10.7"

set -e
set -u

ROOT_DIRECTORY=`pwd`
LOG=${ROOT_DIRECTORY}/${LOG}

trap "echo '-> Build complete!'; echo '-> Last lines of log:'; echo '----------------------------------------'; tail ${LOG}; exit" INT TERM EXIT

#empty out previous log
echo > ${LOG}

echo "-> Logging to ${LOG}"

if [ ! -e llvm ];
then
    echo "-> Checking out llvm source tree..."
    svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm >> "${LOG}" 2>&1
    cd llvm/tools
    svn co http://llvm.org/svn/llvm-project/cfe/trunk clang >> "${LOG}" 2>&1
    cd ../..
else
    echo "-> Source tree found, updating"
    cd llvm
    svn update >> "${LOG}" 2>&1
    cd tools/clang
    svn update >> "${LOG}" 2>&1
    cd ../../..
fi

if [ ! -e BuildTools ];
then
    echo "-> Building native build tools..."
    mkdir BuildTools
    cd BuildTools
    ../llvm/configure --disable-polly >> "${LOG}" 2>&1
    cd ..
    make -C BuildTools ENABLE_OPTIMIZED=1 BUILD_DIRS_ONLY=1 DISABLE_ASSERTIONS=1 >> "${LOG}" 2>&1
else
    echo "-> Native build tools found"
fi

for ARCH in ${ARCHS}
do
    if [ "${ARCH}" == "i386" ];
    then
      PLATFORM="iPhoneSimulator"
      CFLAGS="-mmacosx-version-min=${OSXSDKVERSION}"
  else
      PLATFORM="iPhoneOS"
      CFLAGS="-miphoneos-version-min=${SDKVERSION}"
  fi
  echo "-> Building ${PLATFORM} :"
  if [ ! -e build-${PLATFORM} ];
    then
      mkdir build-${PLATFORM}
    fi
  if [ ! -e install-${PLATFORM} ];
    then
      mkdir install-${PLATFORM}
    fi
    cd build-${PLATFORM}
        
    export DEVROOT=${PLATFORMS_ROOT}${PLATFORM}.platform/Developer
    export SDKROOT=${DEVROOT}/SDKs/${PLATFORM}5.0.sdk
    export CFLAGS="-I${ROOT_DIRECTORY} -isysroot ${SDKROOT} -arch ${ARCH} ${CFLAGS}"
    export CXXFLAGS="${CFLAGS}"
    export LDFLAGS="-lstdc++"
    
    if [ "${ARCH}" != "i386" ];
    then
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
    fi
    
    if [ ! -e include/llvm/Config/config.h ];
    then
        echo "---> Configuring..."
        ../llvm/configure --enable-optimized --disable-shared --disable-docs --host=${ARCH}-apple-darwin11 --prefix=${ROOT_DIRECTORY}/install-${PLATFORM} >> "${LOG}" 2>&1
    else
        echo "---> config.h found, skipping configuring"
    fi
    
    if [ "${ARCH}" == "i386" ];
    then
        echo "---> Building..."
        if ! make TOOL_VERBOSE=1 >> "${LOG}" 2>&1;
        then
            echo "---> Build failed, probably because of a broken llvm-tblgen, copying from native build tools and trying again"
            cp ../BuildTools/Release/bin/llvm-tblgen Release+Asserts/bin/
            if ! make TOOL_VERBOSE=1 >> "${LOG}" 2>&1;
            then
                echo "---> Build failed again, probably because of a broken clang-tblgen, copying from native build tools and trying again"
                cp ../BuildTools/Release/bin/clang-tblgen Release+Asserts/bin/
                make TOOL_VERBOSE=1 >> "${LOG}" 2>&1
            fi
        fi
    else
        echo "---> Building..."
        make TOOL_VERBOSE=1 >> "${LOG}" 2>&1
    fi
    echo "---> Installing to ${ROOT_DIRECTORY}/install-${PLATFORM} ..."
    make install TOOL_VERBOSE=1 >> "${LOG}" 2>&1
    cd ..
done


echo "-> Copying headers..."
cp -r install-iPhoneOS/include .

echo "-> Creating fat libraries..."
if [ ! -e lib ];
then
    mkdir lib
fi
cd install-iPhoneOS

for FILE in lib/*.a
do
    lipo -create ${FILE} ../install-iPhoneSimulator/${FILE} -output ../${FILE}
done
