#!/bin/bash

set -e

LIBGIT2SHA=`cat ./nuget.package/libgit2/libgit2_hash.txt`
SHORTSHA=${LIBGIT2SHA:0:7}
OS=`uname`
ARCH=`uname -m`
PACKAGEPATH="nuget.package/runtimes"
OSXARCHITECTURE=$ARCH

if [[ $OS == "Darwin" ]]; then
    USEHTTPS="ON"
    if [[ $RID == "osx-arm64" ]]; then
        OSXARCHITECTURE="arm64"
    elif [[ $RID == "osx-x64" ]]; then
        OSXARCHITECTURE="x86_64"
    fi
else
    USEHTTPS="OpenSSL-Dynamic"
fi

if [[ $RID == android-* ]]; then
    echo $RID
    cmake --version
    if [[ $ANDROID_NDK_HOME == "" ]]; then
        echo "Error: ANDROID_NDK_HOME not found"
        exit 0
    fi

    if [[ $RID == "android-arm64" ]]; then
        ABI=arm64-v8a
    else 
        ABI=armeabi-v7a
    fi

    $ANDROID_NDK_HOME/ndk-build --version
    CMAKE_ANDROID=" -DCMAKE_SYSTEM_NAME=Android \
                    -DCMAKE_SYSTEM_VERSION=24 \
                    -DCMAKE_ANDROID_ARCH_ABI=$ABI \
                    -DCMAKE_ANDROID_NDK=$ANDROID_NDK_HOME \
                    -DCMAKE_ANDROID_STL_TYPE=gnustl_static \
                    "
    echo $CMAKE_ANDROID
fi

rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

export _BINPATH=`pwd`

cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_TESTS:BOOL=OFF \
      -DUSE_SSH=OFF \
      -DLIBGIT2_FILENAME=git2-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES=$OSXARCHITECTURE \
      -DUSE_HTTPS=$USEHTTPS \
      -DUSE_BUNDLED_ZLIB=ON \
      $CMAKE_ANDROID \
      ..
cmake --build .

popd

if [[ $RID == "" ]]; then
    echo "$(tput setaf 3)RID not defined. Skipping copy to package path.$(tput sgr0)"
    exit 0
fi

if [[ $OS == "Darwin" ]]; then
    LIBEXT="dylib"
else
    LIBEXT="so"
fi

rm -rf $PACKAGEPATH/$RID
mkdir -p $PACKAGEPATH/$RID/native

cp libgit2/build/libgit2-$SHORTSHA.$LIBEXT $PACKAGEPATH/$RID/native
