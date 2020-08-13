#!/bin/bash

set -x

function upload_file {
    BIN_PATH=$1
    BIN_FN=$2
    BIN_SUFFIX=$3
    PASS=$4

    BIN_NAME=${BIN_FN}_${BIN_SUFFIX}
	  cp ${BIN_PATH}/${BIN_FN} $BIN_NAME
	  echo "md5sum = `md5sum $BIN_NAME`";
    ./scp.expect $BIN_NAME $PASS
}  

mkdir -p ~/.ssh

upload_file native_i686-linux-android/tor/src/app  tor x86 $2
upload_file native_arm-linux-androideabi/tor/src/app  tor arm $2
upload_file native_aarch64-linux-android/tor/src/app  tor arm64 $2
upload_file native_x86_64-linux-android/tor/src/app  tor x86_64 $2
