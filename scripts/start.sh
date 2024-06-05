#!/bin/bash -e

hostname=${PWD##*/}
container="$hostname"
tag="1.0"

usage()
{
    echo "usage: ./start [options]"
    echo "options:"
    echo "-h - help"
    echo "-b - build container"
}

run_container()
{
    docker run \
    -it \
    --rm \
    -e "TERM=xterm-256color" \
    --hostname "${hostname}" \
    --name "${hostname}" \
    -v /etc/localtime:/etc/localtime:ro \
    -v "${PWD}":/home/bsp/bsp \
    --workdir /home/bsp/bsp \
    "${container}":"${tag}"
}

build_container()
{
    docker image build docker --no-cache -t "${container}":"${tag}"
}

while getopts "bh" OPTION;
do
    case ${OPTION} in
    b)
        build_container
        exit 0
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
shift "$((OPTIND -1))"

run_container
