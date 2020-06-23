#!/bin/bash

#
# Written and maintained by the.arul@gmail.com (2014)
#

BUILD_DIR="./lib/iOS"

###################################
# 		 SDK Version
###################################
IOS_SDK_VERSION=$(xcodebuild -version -sdk iphoneos | grep SDKVersion | cut -f2 -d ':' | tr -d '[[:space:]]')
###################################

###################################
# 		 BUILD Configuration
###################################

BUILD_SHARED_LIBS=OFF
BUILD_TYPE=Release

################################################
# 		 Minimum iOS deployment target version
################################################
MIN_IOS_VERSION="11.0"

IOS_SDK_TARGET=$MIN_IOS_VERSION
XCODE_ROOT_DIR=$(xcode-select  --print-path)
TOOLCHAIN=$XCODE_ROOT_DIR/Toolchains/XcodeDefault.xctoolchain

CMAKE_C_COMPILER=$(xcrun -find cc)
CMAKE_CXX_COMPILER=$(xcrun -find c++)

BUILD_ARCHS_DEVICE="arm64 arm64e"
BUILD_ARCHS_ALL=($BUILD_ARCHS_DEVICE)

CPP_DEV_TARGET_LIST=(miphoneos-version-min)
CPP_DEV_TARGET=
CPP_STD_LIB_LIST=(libc++ libstdc++)
CPP_STD_LIB=
CPP_STD_LIST=(c++11 c++14)
CPP_STD=c++11

function join { local IFS="$1"; shift; echo "$*"; }

build_arch()
{
    IOS_SDK_DEVICE=iPhoneOS
    CPP_DEV_TARGET=${CPP_DEV_TARGET_LIST[0]}

    unset DEVROOT SDKROOT CFLAGS LDFLAGS CPPFLAGS CXXFLAGS CMAKE_CLI_INPUT
           
	#export CC="$(xcrun -sdk iphoneos -find clang)"
    #export CPP="$CC -E"
    export DEVROOT=$XCODE_ROOT_DIR/Platforms/$IOS_SDK_DEVICE.platform/Developer
    export SDKROOT=$DEVROOT/SDKs/$IOS_SDK_DEVICE$IOS_SDK_VERSION.sdk
    export CFLAGS="-arch $1 -pipe -no-cpp-precomp -fembed-bitcode -stdlib=$CPP_STD_LIB -isysroot $SDKROOT -I$SDKROOT/usr/include/ -miphoneos-version-min=$IOS_SDK_TARGET"
     if [[ "$BUILD_TYPE" =~ "Debug" ]]; then
      export CFLAGS="$CFLAGS -Og"
     else
	     export CFLAGS="$CFLAGS -O3"
     fi
    export LDFLAGS="-arch $1 -isysroot $SDKROOT -L$SDKROOT/usr/lib/"
    export CPPFLAGS="$CFLAGS"
    export CXXFLAGS="$CFLAGS -std=$CPP_STD"
    export OTHER_CFLAGS="-fembed-bitcode"

    #rm CMakeCache.txt
    
    CMAKE_CLI_INPUT="-DCMAKE_C_COMPILER=$CMAKE_C_COMPILER \
    -DCMAKE_CXX_COMPILER=$CMAKE_CXX_COMPILER \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DBUILD_SHARED_LIBS=$BUILD_SHARED_LIBS \
    -DCMAKE_CXX_FLAGS_RELEASE=-g0"
    
    echo "[!] Running CMake with -G 'Unix Makefiles' $CMAKE_CLI_INPUT"
    
    cmake -G 'Unix Makefiles' ${CMAKE_CLI_INPUT}

    echo "[!] Building $1 library"

    xcrun -run make clean
    xcrun -run make -j 8 -l    
    
    rm CMakeCache.txt

    if [[ "$BUILD_SHARED_LIBS" =~ "ON" ]]; then
    	echo "[!] Moving built dynamic libraries into: $BUILD_DIR/$1/"
    	mv ./lib/*.dylib  $BUILD_DIR/$1/
    fi
    
    echo "[!] Moving built static libraries into: $BUILD_DIR/$1/"
    mv ./lib/*.a $BUILD_DIR/$1/	   
}

CPP_STD_LIB=${CPP_STD_LIB_LIST[0]}
CPP_STD=${CPP_STD_LIST[0]}
DEPLOY_ARCHS=${BUILD_ARCHS_ALL[*]}
DEPLOY_FAT=1

for i in "$@"; do
    case $i in
    -s=*|--std=*)
        CPP_STD=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
        echo "[!] Selecting c++ standard: $CPP_STD"
    ;;
    -l=*|--stdlib=*)
        CPP_STD_LIB=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
        echo "[!] Selecting c++ std lib: $CPP_STD_LIB"
    ;;
    -a=*|--archs=*)
        DEPLOY_ARCHS=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
        echo "[!] Selecting architectures: $DEPLOY_ARCHS"
    ;;
    --debug)
    	BUILD_TYPE=Debug        
        echo "[!] Selecting build type: Debug"
    ;;
    --shared-lib)
    	BUILD_SHARED_LIBS=ON        
        echo "[!] Will generate dynamic libraries"
    ;;
    -n|--no-fat)
        DEPLOY_FAT=0
        echo "[!] Fat binary will not be created."
    ;;
    -h|--help)
        echo " - don't build fat library (--no-fat)."
        echo " - Include debug information and symbols, no compiler optimizations (--debug)."
        echo " - generate dynamic libraries rather than static ones (--shared-lib)."
        echo " - supported architectures (--archs):  $(echo $(join , ${BUILD_ARCHS_ALL[*]}) | sed 's/,/, /g')"
        echo " - supported C++ STD libs (--stdlib): $(echo $(join , ${CPP_STD_LIB_LIST[*]}) | sed 's/,/, /g')"
        echo " - supported C++ standards (--std): $(echo $(join , ${CPP_STD_LIST[*]}) | sed 's/,/, /g')"
        exit
    ;;
    *)
    ;;
    esac
done

rm -rf $BUILD_DIR

for ARCH_TARGET in $DEPLOY_ARCHS; do
	echo "Creating folder: $BUILD_DIR/$ARCH_TARGET"
    mkdir -p $BUILD_DIR/$ARCH_TARGET
    echo "Building for arc: $ARCH_TARGET" 
    build_arch $ARCH_TARGET
done