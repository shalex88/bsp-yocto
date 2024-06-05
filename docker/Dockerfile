FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Upgrade system and Yocto Project basic dependencies
RUN apt-get update && \
apt-get -y install gawk wget git diffstat unzip texinfo gcc build-essential \
chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
xterm python3-subunit mesa-common-dev zstd liblz4-tool u-boot-tools rsync file

# Fix "server cerificate verification failed" error
RUN apt-get -y install ntp apt-transport-https ca-certificates

# Support opening menuconfig in Yocto environment
RUN apt-get -y install screen

# Set up locales
RUN apt-get -y install locales apt-utils sudo && \
dpkg-reconfigure locales && \
locale-gen en_US.UTF-8 && \
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.utf8

# Fix for nxp-wlan-sdk missing libraries
RUN apt-get install -y linux-headers-generic
RUN ln -s /lib/modules/* /lib/modules/$(uname -r)

# Clean up APT when done
RUN apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Replace dash with bash
RUN rm /bin/sh && ln -s bash /bin/sh

# Create user
ENV HOME /home/bsp
ENV USER bsp
RUN export uid=1000 gid=1000 && \
mkdir -p /home/${USER} && \
echo "${USER}:x:${uid}:${gid}:${USER},,,:${HOME}:/bin/bash" >> /etc/passwd && \
echo "${USER}:x:${uid}:" >> /etc/group && \
echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} && \
chmod 0440 /etc/sudoers.d/${USER} && \
chown ${uid}:${gid} -R ${HOME}
USER ${USER}
