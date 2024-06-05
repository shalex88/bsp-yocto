#!/bin/bash -e

echo "Clone yocto sources"

directory="yocto"
bsp_version="langdale" #L4T R35.2.1 https://github.com/OE4T/tegra-demo-distro/wiki/Which-branch-should-I-use%3F

# Clone poky and other layers
git clone https://github.com/OE4T/tegra-demo-distro.git ${directory}
cd $directory
git checkout $bsp_version
git submodule update --init

echo "Done"
