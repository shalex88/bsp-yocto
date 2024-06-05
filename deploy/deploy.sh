#!/bin/bash

# ./deploy.sh <IMAGE> <MACHINE>
# ./deploy.sh demo-image-full jetson-agx-orin-devkit
sudo apt install device-tree-compiler

IMAGE=demo-image-full
MACHINE=jetson-agx-orin-devkit

if [ -z "$1" ]; then
    image=$IMAGE
else 
    image=$1
fi

if [ -z "$2" ]; then
    machine=$MACHINE
else
    machine=$2
fi

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
deployfile=${image}-${machine}.tegraflash.tar.gz
tmpdir=$(mktemp)

rm -rf "$tmpdir"
mkdir -p "$tmpdir"
echo "Using temp directory $tmpdir"
pushd "$tmpdir"
cp "$scriptdir"/../yocto/build/tmp/deploy/images/"${machine}"/"$deployfile" .
tar -xvf "$deployfile"
set -e
sudo ./doflash.sh
popd
echo "Removing temp directory $tmpdir"
rm -rf "$tmpdir"

echo "Done"