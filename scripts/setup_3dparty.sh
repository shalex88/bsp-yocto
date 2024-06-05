#!/bin/bash -e

echo "Setup 3dparty Yocto layers"

bsp_version=${1}

pushd ~/bsp/yocto/layers > /dev/null
git clone https://github.com/hailo-ai/meta-hailo -b "${bsp_version}"
git clone https://github.com/shalex88/meta-shalex -b "${bsp_version}"
popd > /dev/null

# Add Hailo layers
pushd ~/bsp/yocto/build/conf > /dev/null
echo -E '
BBLAYERS += "${BBPATH}/../layers/meta-hailo/meta-hailo-accelerator"
BBLAYERS += "${BBPATH}/../layers/meta-hailo/meta-hailo-libhailort"
BBLAYERS += "${BBPATH}/../layers/meta-hailo/meta-hailo-tappas"
BBLAYERS += "${BBPATH}/../layers/meta-shalex"
' >> bblayers.conf
popd > /dev/null

echo "Done"
