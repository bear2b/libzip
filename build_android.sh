NDK=~/ndk/android-ndk-r20
LIB_NAME=libzip.a
ALL_ABIS=(arm64-v8a armeabi-v7a) 

function build_libzip {

cmake	-DANDROID_NDK=${NDK} \
		-DCMAKE_TOOLCHAIN_FILE=${NDK}/build/cmake/android.toolchain.cmake \
     	-DANDROID_NATIVE_API_LEVEL=21 \
     	-DANDROID_ABI=${ANDROID_ABI} \
     	-DBUILD_SHARED_LIBS=OFF \
     	-DAPP_STL="c++_static" \
     	-DCMAKE_BUILD_TYPE="release" \
     	-G"Unix Makefiles" \
    	..
  
make
}

for ANDROID_ABI in ${ALL_ABIS[*]}; do

mkdir build
cd build
mkdir ../libs

mkdir ../libs/${ANDROID_ABI}
echo "Building for ABI: $ANDROID_ABI" 
  	
build_libzip $ANDROID_ABI
mv ./lib/${LIB_NAME} ../libs/${ANDROID_ABI}

cd ..
rm -rf ./build

done