#!/bin/bash -e

usage()
{
	echo -e "usage:"
	echo -e "\t./$(basename $0) -r REVISION [options]"
	echo -e "options:"
	echo -e "\t-p - path to BSP build directory"
	echo -e "\t-m - Yocto machine name"
	echo -e "\t-i - Yocto image name"
	echo -e "\t-t - Yocto image type [wic|tar]"
	echo -e "\t-r - revision to create"
	echo -e "\t-h - help"
	echo -e "example:"
	echo -e "\t./$(basename $0) -p /mnt/sda4/bsp-imx8mp-kirkstone-build -m imx8mp-var-dart -i my-image -t wic -r 11"
}

get_latest_bsp()
{
	BSP_FILE_PATH=${BUILD_DIR}/tmp/deploy/images/${BSP_MACHINE_NAME}
	cp ${BSP_FILE_PATH}/${BSP_IMAGE_NAME}-${BSP_MACHINE_NAME}.$BSP_IMAGE_TYPE.gz ${BSP_PACKAGE_NAME}/${BSP_FILE}
	cp ${BSP_FILE_PATH}/imx-boot ${BSP_PACKAGE_NAME}/${UBOOT_FILE}
	cp ${BSP_FILE_PATH}/${DT_FILE} ${BSP_PACKAGE_NAME}/${DT_FILE}
	cp ${BSP_FILE_PATH}/${BOOT_SCR_FILE} ${BSP_PACKAGE_NAME}/${BOOT_SCR_FILE}

	cp ${BSP_FILE_PATH}/${BSP_IMAGE_NAME}-${BSP_MACHINE_NAME}.manifest ${BSP_PACKAGE_NAME}/${BSP_PACKAGES_FILE}
	cp "$(ls -d ${BUILD_DIR}/tmp/deploy/licenses/${BSP_IMAGE_NAME}-* | tail -1)"/license.manifest ${BSP_PACKAGE_NAME}/${LICENSE_FILE}
}

get_latest_sdk()
{
	SDK_FILE_PATH=${BUILD_DIR}/tmp/deploy/sdk

	cp ${SDK_FILE_PATH}/${SDK}.sh ${BSP_PACKAGE_NAME}/sdk.sh
	cat ${SDK_FILE_PATH}/${SDK}.host.manifest > ${BSP_PACKAGE_NAME}/"$SDK_PACKAGES_FILE"
	cat ${SDK_FILE_PATH}/${SDK}.target.manifest >> ${BSP_PACKAGE_NAME}/"$SDK_PACKAGES_FILE"
}

get_versions()
{
	UBOOT_VER=$(strings ${BSP_PACKAGE_NAME}/${UBOOT_FILE} | grep "U-Boot SPL" | awk -F" " '{print $1,$2,$3}')
	DT_VER=$(strings ${BSP_PACKAGE_NAME}/${DT_FILE} | grep "Version" | awk -F" " '{print $3}')
	BOOTSCR_VER=$(strings ${BSP_PACKAGE_NAME}/${BOOT_SCR_FILE} | grep "Version" | awk -F" " '{print $4}')
	ROOTFS_VER=$(ls ${BSP_FILE_PATH}/${BSP_IMAGE_NAME}-${BSP_MACHINE_NAME}-*.$BSP_IMAGE_TYPE.gz | awk -F"${BSP_MACHINE_NAME}-" '{print $2}' | awk -F".rootfs" '{print $1}')
	KERNEL_VER=$(cat ${BSP_FILE_PATH}/${BSP_IMAGE_NAME}-${BSP_MACHINE_NAME}-*.rootfs.manifest | grep imx8mp+ -m 1 | awk -F" " '{print $1}' | awk -F"kernel-" '{print $NF}')
	DEVICE_MODEL=$(strings ${BSP_PACKAGE_NAME}/${DT_FILE} | grep 7 -m1 | cut -c 2-)

	echo "Device = ${DEVICE_MODEL}" > ${BSP_PACKAGE_NAME}/${VERSION_FILE}
	echo "Uboot = ${UBOOT_VER}" >> ${BSP_PACKAGE_NAME}/${VERSION_FILE}
	echo "Kernel = ${KERNEL_VER}" >> ${BSP_PACKAGE_NAME}/${VERSION_FILE}
	echo "Device Tree = ${DT_VER}" >> ${BSP_PACKAGE_NAME}/${VERSION_FILE}
	echo "Boot Script = ${BOOTSCR_VER}" >> ${BSP_PACKAGE_NAME}/${VERSION_FILE}
	echo "RootFS = ${ROOTFS_VER}" >> ${BSP_PACKAGE_NAME}/${VERSION_FILE}
}

archive()
{
	zip -r ${VERSIONED_BSP_PACKAGE_NAME}.zip ${BSP_PACKAGE_NAME}
}

upload()
{
	# TODO: upload via layout to be able to download the latest revision
	MY_TOKEN=$(cat jf_token)
	curl --oauth2-bearer ${MY_TOKEN} -T ${VERSIONED_BSP_PACKAGE_NAME}.zip "http://artifactory/artifactory/bsp/${BSP_MACHINE_NAME}/${BSP_IMAGE_NAME}/${VERSIONED_BSP_PACKAGE_NAME}.zip"
}

# Input arguments
while getopts "p:m:i:r:t:h" OPTION;
do
	case ${OPTION} in
	p)
		BUILD_DIR=${OPTARG}
		;;
	m)
		BSP_MACHINE_NAME=${OPTARG}
		;;
	i)
		BSP_IMAGE_NAME=${OPTARG}
		;;	
	t)
		BSP_IMAGE_TYPE=${OPTARG}
		;;
	r)
		# TODO: automate revision increment
		REVISION=${OPTARG}
		;;
	h)
		usage
		exit 0
		;;
	?)
		usage
		exit 1
		;;
	esac
done
shift "$(($OPTIND -1))"

# Mandatory arguments
if [[ -z "$REVISION" || -z "$BUILD_DIR" || -z "$BSP_MACHINE_NAME" || -z "$BSP_IMAGE_NAME" || -z "$BSP_IMAGE_TYPE" ]]; then
	usage
	exit 1
fi

# Global variables
UBOOT_FILE=imx-boot-sd.bin
BSP_FILE=rootfs.$BSP_IMAGE_TYPE.gz
DT_FILE=imx8mp-var-dart.dtb
BOOT_SCR_FILE=boot.scr
# FIXME: this SDK name suits only kirkstone builds
SDK=fslc-xwayland-glibc-x86_64-${BSP_IMAGE_NAME}-armv8a-${BSP_MACHINE_NAME}-toolchain-*
BSP_PACKAGE_NAME=${BSP_IMAGE_NAME}-${BSP_MACHINE_NAME}
VERSIONED_BSP_PACKAGE_NAME=${BSP_PACKAGE_NAME}-${REVISION}
VERSION_FILE=bsp_version.txt
BSP_PACKAGES_FILE=bsp_packages.txt
SDK_PACKAGES_FILE=sdk_packages.txt
LICENSE_FILE=bsp_licenses.txt

# Main
mkdir -p ${BSP_PACKAGE_NAME}

get_latest_sdk
get_latest_bsp

get_versions

archive

# upload

echo "BSP package was successfully created"
cat ${BSP_PACKAGE_NAME}/${VERSION_FILE}
