#!/bin/bash -e

# TODO: fix ssh keygen message

# Escape infinit while loop in check_connection()
trap printout SIGINT
printout() {
    exit
}

usage()
{
	echo -e "usage:"
	echo -e "\t./$(basename $0) -t TARGET IP [options]"
	echo -e "options:"
	echo -e "\t-h - help"
	echo -e "\t-s STATIC IP - static ip"
	echo -e "example:"
	echo -e "\t./$(basename $0) -t 10.199.250.4 -s 10.199.251.4"
}

check_connection()
{
	echo -n "Test the target connection"
	target_ip=${1}
	while ! ping -c 1 -w 1 -n ${target_ip} &> /dev/null; do
		echo -n "."
	done
	echo ""
}

create_connection_profiles()
{
	${EXEC_ON_TARGET} "if ! nmcli con show static-${NET_DEVICE} &> /dev/null; then nmcli con add type ethernet ifname ${NET_DEVICE} con-name static-${NET_DEVICE} ip4 ${NEW_TARGET_IP}/16 method none; fi"
	${EXEC_ON_TARGET} "if ! nmcli con show auto-${NET_DEVICE} &> /dev/null; then nmcli con add type ethernet ifname ${NET_DEVICE} con-name auto-${NET_DEVICE} method auto; fi"
}

modify_connections()
{
	if [ "${CON_TYPE}" == "static" ]; then
		${EXEC_ON_TARGET} "fw_setenv ip_dyn no"
		${EXEC_ON_TARGET} "fw_setenv ipaddr ${NEW_TARGET_IP}"
		${EXEC_ON_TARGET} "nmcli con modify ${CON_NAME} ipv4.addr ${NEW_TARGET_IP}/16 connection.autoconnect-priority 1"
	elif [ "${CON_TYPE}" == "auto" ]; then
		${EXEC_ON_TARGET} "fw_setenv ip_dyn yes"
		${EXEC_ON_TARGET} "fw_setenv ipaddr"
	fi
}

enable_profile()
{
	${EXEC_ON_TARGET} "nmcli con up ${CON_NAME} &>/dev/null & exit"
}


CON_TYPE="auto"

while getopts "t:s:uh" OPTION;
do
	case ${OPTION} in
	t)
		TARGET_IP=${OPTARG}
		;;
	s)
		NEW_TARGET_IP=${OPTARG}
		CON_TYPE="static"
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
if [ -z "$TARGET_IP" ]; then
	usage
	exit 1
fi

# Target configuration
NET_DEVICE=eth0
TARGET_USER=root
TARGET=${TARGET_USER}@${TARGET_IP}
EXEC_ON_TARGET="ssh ${TARGET}"

CON_NAME="${CON_TYPE}-${NET_DEVICE}"

check_connection ${TARGET_IP}
create_connection_profiles
modify_connections
enable_profile

if [ "${CON_TYPE}" == "static" ]; then
	check_connection ${NEW_TARGET_IP}
fi

echo "Network profile was successfully applied"
