#!/bin/sh


# Add deps
sudo apt update
sudo apt-get install expect

sudo apt-get install g++-multilib libc6-dev-i386
sudo apt-get install libc6-i386 lib32z1 lib32stdc++6

# preparing custom rust build
cat helpers/ndk_21_1/ndk_* | bzip2 -dc | tar xvf -

