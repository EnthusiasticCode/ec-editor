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
    # cd llvm
    # svn update >> "${LOG}" 2>&1
    # cd tools/clang
    # svn update >> "${LOG}" 2>&1
    # cd ../../..
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

# for ARCH in ${ARCHS}
# do
#     if [ "${ARCH}" == "i386" ];
#     then
#       PLATFORM="iPhoneSimulator"
#       CFLAGS="-mmacosx-version-min=${OSXSDKVERSION}"
#   else
#       PLATFORM="iPhoneOS"
#       CFLAGS="-miphoneos-version-min=${SDKVERSION}"
#   fi
#   echo "-> Building ${PLATFORM} :"
#   if [ ! -e build-${PLATFORM} ];
#     then
#       mkdir build-${PLATFORM}
#     fi
#   if [ ! -e install-${PLATFORM} ];
#     then
#       mkdir install-${PLATFORM}
#     fi
#     cd build-${PLATFORM}
#         
#     export DEVROOT=${PLATFORMS_ROOT}${PLATFORM}.platform/Developer
#     export SDKROOT=${DEVROOT}/SDKs/${PLATFORM}5.0.sdk
#     export CFLAGS="-I${ROOT_DIRECTORY} -isysroot ${SDKROOT} -arch ${ARCH} ${CFLAGS}"
#     export CXXFLAGS="${CFLAGS}"
#     export LDFLAGS="-lstdc++"
#     
#     if [ "${ARCH}" != "i386" ];
#     then
#         export CC=$DEVROOT/usr/bin/clang
#         export BUILD_CC=$DEVROOT/usr/bin/clang
#         export BUILD_CXX=$DEVROOT/usr/bin/clang
#         export LD=$DEVROOT/usr/bin/ld
#         export CPP="$DEVROOT/usr/bin/clang -E"
#         export CXX=$DEVROOT/usr/bin/clang
#         export AR=$DEVROOT/usr/bin/ar
#         export AS=$DEVROOT/usr/bin/as
#         export NM=$DEVROOT/usr/bin/nm
#         export CXXCPP="$DEVROOT/usr/bin/clang -E"
#     fi
#     
#     if [ ! -e include/llvm/Config/config.h ];
#     then
#         echo "---> Configuring..."
#         ../llvm/configure --enable-optimized --disable-shared --disable-docs --host=${ARCH}-apple-darwin11 --prefix=${ROOT_DIRECTORY}/install-${PLATFORM} >> "${LOG}" 2>&1
#     else
#         echo "---> config.h found, skipping configuring"
#     fi
#     
#     if [ "${ARCH}" == "i386" ];
#     then
#         echo "---> Building..."
#         if ! make TOOL_VERBOSE=1 >> "${LOG}" 2>&1;
#         then
#             echo "---> Build failed, probably because of a broken llvm-tblgen, copying from native build tools and trying again"
#             cp ../BuildTools/Release/bin/llvm-tblgen Release+Asserts/bin/
#             if ! make TOOL_VERBOSE=1 >> "${LOG}" 2>&1;
#             then
#                 echo "---> Build failed again, probably because of a broken clang-tblgen, copying from native build tools and trying again"
#                 cp ../BuildTools/Release/bin/clang-tblgen Release+Asserts/bin/
#                 make TOOL_VERBOSE=1 >> "${LOG}" 2>&1
#             fi
#         fi
#     else
#         echo "---> Building..."
#         make TOOL_VERBOSE=1 >> "${LOG}" 2>&1
#     fi
#     echo "---> Installing to ${ROOT_DIRECTORY}/install-${PLATFORM} ..."
#     make install TOOL_VERBOSE=1 >> "${LOG}" 2>&1
#     cd ..
# done


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

# #For both:
# svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm
# cd llvm/tools
# svn co http://llvm.org/svn/llvm-project/cfe/trunk clang
# cd ..
# 
# #If you already have sources:
# #make update
# 
# sudo cp /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator5.0.sdk/usr/include/crt_externs.h $SDKROOT/usr/include
# 
# #Make cross-compile build tools:
# mkdir BuildTools
# cd BuildTools
# #if it complains about "already configured" delete / move include/llvm/Config/config.h
# ../configure --build=x86_64-apple-darwin11.2.0 --host=x86_64-apple-darwin11.2.0 --target=x86_64-apple-darwin11.2.0 --disable-polly
# cd ..
# make -C BuildTools ENABLE_OPTIMIZED=1 BUILD_DIRS_ONLY=1 DISABLE_ASSERTIONS=1
# 
# #For ipad:
# 
# export DEVROOT=/Developer/Platforms/iPhoneOS.platform/Developer
# export SDKROOT=$DEVROOT/SDKs/iPhoneOS5.0.sdk
# export CFLAGS="-isysroot $SDKROOT -arch armv7 -miphoneos-version-min=5.0"
# export CXXFLAGS="-isysroot $SDKROOT -arch armv7 -miphoneos-version-min=5.0"
# export LDFLAGS="-isysroot $SDKROOT -arch armv7 -miphoneos-version-min=5.0 -lstdc++"
# 
# #For simulator:
# 
# export DEVROOT=/Developer/Platforms/iPhoneSimulator.platform/Developer
# export SDKROOT=$DEVROOT/SDKs/iPhoneSimulator5.0.sdk
# export CFLAGS="-isysroot $SDKROOT -arch i386 -mmacosx-version-min=10.7"
# export CXXFLAGS="-isysroot $SDKROOT -arch i386 -mmacosx-version-min=10.7"
# export LDFLAGS="-isysroot $SDKROOT -arch i386 -mmacosx-version-min=10.7 -lstdc++"
# 
# #For both:
# 
# export CC=$DEVROOT/usr/bin/clang
# export BUILD_CC=$DEVROOT/usr/bin/clang
# export BUILD_CXX=$DEVROOT/usr/bin/clang
# export LD=$DEVROOT/usr/bin/ld
# export CPP="$DEVROOT/usr/bin/clang -E"
# export CXX=$DEVROOT/usr/bin/clang
# export AR=$DEVROOT/usr/bin/ar
# export AS=$DEVROOT/usr/bin/as
# export NM=$DEVROOT/usr/bin/nm
# export CXXCPP="$DEVROOT/usr/bin/clang -E"
# 
# #For ipad:
# 
# ./configure --enable-optimized --disable-shared --disable-docs --host=armv7-apple-darwin11 --prefix=$SDKROOT/usr
# make
# sudo make install UNIVERSAL=1 UNIVERSAL_ARCH=armv7 UNIVERSAL_SDK_PATH=$SDKROOT
# sudo rm $SDKROOT/usr/lib/libclang.dylib
# 
# #For simulator:
# 
# ./configure --enable-optimized --disable-shared --disable-docs --host=i386-apple-darwin11 --prefix=$SDKROOT/usr
# make
# 
# #this will eventually fail because tblgen can't find Intrinsic class
# #that's because llvm-tblgen and clang-tblgen are broken when compiled for i386, just copy over the buildtools bins from the cross compile build
# cp ~/Desktop/BuildTools/Release/bin/* ./Release/bin/
# #and make again
# make
# 
# sudo make install UNIVERSAL_ARCH=i386 UNIVERSAL_SDK_PATH=$SDKROOT
# sudo rm $SDKROOT/usr/lib/libclang.dylib
# 
# #After building ipad:
# #backup BuildTools on desktop
# cp -r BuildTools ~/Desktop/
# make clean
