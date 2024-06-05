#!/bin/bash -e

echo "Project setup"

# Set build settings
pushd conf > /dev/null
ln -sf ../../../scripts/site.conf site.conf

# Disable sanity test preventing building on nfs
touch sanity.conf

popd > /dev/null
echo "Done"
