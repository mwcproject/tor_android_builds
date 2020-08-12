# mwc713-android-builds

Repository for Tor Android Builds. 
Here we have everythign to build Tor for Android. Supporting 4 ABI:  x86, x86-64, arm, arm64

setup_linux.sh - install NDK and needed packages

build_tor.sh - build tor for a single ABI for Android

deploy_linux.sh - upload build result to nightly build server

----------------------

Settings:

At  build_tor.sh  you can select versions of the components 
```
wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1g.tar.gz
git clone https://github.com/marcotessarotto/libevent
export TOR_BRANCH="release-0.4.4"
``` 

----------------------

How to compress:
```
rm -rf ndk_21_1_6352462
cp -a ~/Android/Sdk/ndk/ndk.21.1.6352462  ndk_21_1_6352462

Clean up platforms at ndk_21_1_6352462/platforms/
We need 19 & 21 only

tar cvfj helpers/ndk_21_1_6352462/ndk.tar.bz2  ndk_21_1_6352462
split -b 40m -a 3 helpers/ndk_21_1_6352462/ndk.tar.bz2 helpers/ndk_21_1_6352462/ndk_
rm helpers/ndk_21_1_6352462/ndk.tar.bz2
```
Results at helpers/ndk_21_1_6352462/: ndk_aaa  .....


How to extract:
cat helpers/ndk_21_1_6352462/ndk_* | bzip2 -dc | tar xvf -

