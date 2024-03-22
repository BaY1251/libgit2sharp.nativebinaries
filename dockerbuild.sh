#!/bin/bash

set -e
echo "building for $RID"

if [[ $RID =~ arm64 ]]; then
    arch="arm64"
elif [[ $RID =~ arm ]]; then
    arch="armhf"
else
    arch="amd64"
fi

if [[ $RID == android* ]]; then
    dockerfile="Dockerfile.android"
elif [[ $RID == linux-musl* ]]; then
    dockerfile="Dockerfile.linux-musl"
else
    dockerfile="Dockerfile.linux"
fi

docker buildx build -t $RID -f $dockerfile --build-arg ARCH=$arch .

docker run -t -e RID=$RID -e ANDROID_NDK_HOME=$ANDROID_NDK_HOME --name=$RID $RID

docker cp $RID:/nativebinaries/nuget.package/runtimes nuget.package

docker rm $RID
