#!/bin/bash -e

usage()
{
	echo -e "usage:"
	echo -e "\t./$(basename $0) -t TARGET_IP [options]"
	echo -e "options:"
	echo -e "\t-h - help"
	echo -e "\t-r - revision to install (default: latest)"
	echo -e "\t-m - Yocto machine name"
	echo -e "\t-i - Yocto image name"
	echo -e "example:"
	echo -e "\t./$(basename $0) -t 10.199.250.4 -m imx8mp-var-dart -i my-image -r 2"
}

transfer_and_validate()
{
	FILE=${1}

	script -q -c "scp ${FILE} ${TARGET}:${DESTINATION_DIR}"
	${EXEC_ON_TARGET} "sync"

	LOCAL_MD5SUM=$(md5sum ${FILE} | cut -d ' ' -f1)
	REMOTE_MD5SUM=$(${EXEC_ON_TARGET} "md5sum ${FILE} | cut -d ' ' -f1")

	if [ "${LOCAL_MD5SUM}" != "${REMOTE_MD5SUM}" ]; then
		echo -e "Error: Not matching md5sum!"
		exit
	fi
}

download_from_artifactory()
{
	# Install Jason parser if not installed
	if ! command -v jq >/dev/null 2>&1; then
		echo "jq is not installed. Installing jq now..."
		sudo apt-get update
		sudo apt-get install -y jq
		if [ $? -eq 0 ]; then
			echo -e "ERROR: Failed to install dependencies, abort"
			exit 1
		fi
	fi

	artifacts_list=$(wget -qO- "${ARTIFACTORY_URL}/api/storage/${REPO_NAME}/${BSP_MACHINE_NAME}/${BSP_IMAGE_NAME}")
	if [ $? -eq 0 ]; then
		if [ -z "${REVISION}" ]; then
			local bsp_package=$(echo "$artifacts_list" | jq -r --arg prefix "/$BSP_PACKAGE_NAME" '.children[] | select(.uri | test("^" + $prefix + "-\\d+\\.zip$")) | .uri | ltrimstr("/")' | sort -V | tail -n 1)
		else
			local bsp_package=${BSP_PACKAGE_NAME}-${REVISION}.zip
		fi

		if [ ! -f "${bsp_package}" ]; then
			DOWNLOAD="wget -q --show-progress --progress=bar ${ARTIFACTORY_URL}/${REPO_NAME}/${BSP_MACHINE_NAME}/${BSP_IMAGE_NAME}/${bsp_package} -P $(pwd)/"
			if ! $($DOWNLOAD); then
				echo -e "Error: BSP package download failed"
				exit 1
			fi
		else
			bsp_package="local"
		fi
	else
		echo -e "Warning: Failed to download, local package will be installed" >& 2
		local bsp_package="local"
	fi

	echo -e "${bsp_package}"
}

get_bsp_package()
{
	echo -e "Get latest BSP:"

	result=$(download_from_artifactory)

	if [ "${result}" == "local" ]; then
		if [ -z "${REVISION}" ]; then
			local latest_bsp_package=$(ls ${BSP_PACKAGE_NAME}*.zip 2> /dev/null)
		else
			local latest_bsp_package=${BSP_PACKAGE_NAME}-${REVISION}.zip
		fi
		if [ -z "$latest_bsp_package" ]; then
			echo -e "Error: No BSP package available locally"
			exit 1
		fi
	else
		local latest_bsp_package=${result}
	fi

	echo -e "Package ${latest_bsp_package} will be installed"

	unzip -o ${latest_bsp_package}

	pushd ${BSP_PACKAGE_NAME} > /dev/null

	check_bsp_package_type

	echo -e "Package version:"
	cat bsp_version.txt

  	echo -e "Done"
}

check_bsp_package_type()
{
	file=$(ls ${BSP_FILE_NAME}.*)
    extension="${file%.*}"
	BSP_FILE_TYPE="${extension##*.}.gz"

	BSP_FILE="${BSP_FILE_NAME}.${BSP_FILE_TYPE}"
	TARGET_INSTALL_SCRIPT="${TARGET_INSTALL_SCRIPT_NAME}_${BSP_FILE_TYPE}"
}

copy_to_target()
{
	echo -e "Copy files to target:"

	transfer_and_validate ${BSP_FILE}
	transfer_and_validate ${UBOOT_FILE}
	popd > /dev/null
	transfer_and_validate ${TARGET_INSTALL_SCRIPT}

	echo -e "Done"
}

cleanup()
{
	echo -e "Cleanup:"

	${EXEC_ON_TARGET} "rm ${BSP_FILE}"
	${EXEC_ON_TARGET} "rm ${UBOOT_FILE}"
	${EXEC_ON_TARGET} "rm ${TARGET_INSTALL_SCRIPT}"

	echo -e "Done"
}


check_taget_connection()
{
	echo -n "Test target connection"
	target_ip=${1}
	while ! ping -c 1 -w 1 -n ${target_ip} &> /dev/null; do
		echo -n "."
	done
	echo ""
	echo "Connected"
}

# Input arguments
while getopts "t:r:m:i:h" OPTION;
do
	case ${OPTION} in
	t)
		TARGET_IP=${OPTARG}
		;;
	r)
		REVISION=${OPTARG}
		;;
	m)
		BSP_MACHINE_NAME=${OPTARG}
		;;
	i)
		BSP_IMAGE_NAME=${OPTARG}
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
if [[ -z "$TARGET_IP" || -z "$BSP_MACHINE_NAME" || -z "$BSP_IMAGE_NAME" ]]; then
	usage
	exit 1
fi

ARTIFACTORY_URL="http://artifactory/artifactory"
REPO_NAME="bsp"
BSP_PACKAGE_NAME=${BSP_IMAGE_NAME}-${BSP_MACHINE_NAME}
BSP_FILE_NAME=rootfs
TARGET_INSTALL_SCRIPT_NAME=target_bsp_install.sh

# Global variables
TARGET_USER=root
TARGET=${TARGET_USER}@${TARGET_IP}
EXEC_ON_TARGET="ssh ${TARGET}"
DESTINATION_DIR=/home/root/
UBOOT_FILE=imx-boot-sd.bin

# Main
check_taget_connection ${TARGET_IP}

DEVICE_SERIAL_NUMBER=$(${EXEC_ON_TARGET} "tr -d '\0' < /proc/device-tree/serial-number")

mkdir -p log

(
	date +%d-%m-%Y-%H:%M
	echo -e "System SN ${DEVICE_SERIAL_NUMBER}"

	get_bsp_package

	copy_to_target

	echo -e "Install:"
	${EXEC_ON_TARGET} "./${TARGET_INSTALL_SCRIPT} 2>&1"

	cleanup

	echo -e "Reboot target:"
	${EXEC_ON_TARGET} "nohup reboot &>/dev/null & exit"
	echo -e "Done"

	echo -e "BSP install is finished"
	echo -e "Log log/bsp_install_${DEVICE_SERIAL_NUMBER}.log"
) 2>&1 | tee log/bsp_install_${DEVICE_SERIAL_NUMBER}.log