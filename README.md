# bsp-nvidia-orin-langdale

## Download

```bash
git clone https://github.com/shalex88/bsp-yocto.git -b bsp-nvidia-orin-langdale bsp-nvidia-orin-langdale
```

## Build

### 1. Build docker container

```bash
./scripts/start.sh -b
```

### 2. Run docker container

```bash
./scripts/start.sh
```

### 3. Get yocto sources

```bash
./scripts/clone_yocto.sh
```

### 4. Setup build environment

```bash
cd yocto
. setup-env --machine jetson-agx-orin-devkit
```

### 5. Configure cutom project

```bash
./../../scripts/project_setup.sh
./../../scripts/setup_3dparty.sh zeus #TODO: Update to langdale
```

### 6. Fetch all sources

```bash
bitbake demo-image-full --runonly=fetch -k
bitbake meta-toolchain --runonly=fetch -k
```

### 7. Build the image

```bash
# Append MemoryLimit=8G to limit the memory usage
bitbake demo-image-full
```

### 8. Create package

Usage

```bash
./create_bsp_package.sh -h
```

Create package

```bash
./create_bsp_package.sh -p /mnt/sda4/bsp-imx8mp-kirkstone-build -m imx8mp-var-dart -i my-image -t wic -r 11
```

## Deploy

Usage

```bash
./install_bsp.sh -h
```

Install

```bash
# Stop at Uboot and run
setenv ip_dyn yes; setenv boot_fit no; setenv serverip 10.199.250.35; setenv nfsroot /nfs/bsp/bsp-netboot/imx8mp/rootfs; setenv bootcmd "run netboot";  boot

# Check target IP via serial port

# Start the install from your host PC
./install_bsp.sh -t 10.199.250.4 -m imx8mp-var-dart -i my-image
```

## Set IP for remote linux target

Usage

```bash
./set_target_ip.sh -h
```

Set dynamic IP

```bash
./set_target_ip.sh -t 10.199.250.10
```

Set new static IP

```bash
./set_target_ip.sh -t 10.199.250.10 -s 10.199.251.12
```
