#!/bin/bash

echo "ATTENTION!!!! BATCH Mode active!!! All data on selected device will be lost"
echo "Please configure your network manually!"
echo "You can start a sshd server by '/etc/init.d/sshd start'"
echo "Setup a new root password with 'passwd root'. This is your SSH-Login-Password"

echo "Do you want to proceed (y or N)?"
read answer
if [ $answer == "y" ]; then
	echo "Loading necessary kernel modules..."
	modprobe dm-mod dm-crypt sha256
	
	echo "Create and activate the LVM Setup..."
#	echo "Please select a device:"
#	read device
	echo "The size of boot [MB]:"
	read partsize_boot
	echo "The size of swap [GB]:"
	read partsize_swap
	echo "The size of root [GB]:"
	read partsize_root
	echo "The size of usr [GB]:"
	read partsize_usr
	echo "The size of var [GB]:"
	read partsize_var
	echo "The size of opt [GB]:"
	read partsize_opt
	echo "The size of tmp [GB]:"
	read partsize_tmp
	echo "The size of home [GB]:"
	read partsize_home

#	echo "Formatting device will be : $[device]"
	echo "The size of the boot partition will be : $[partsize_boot]M"
	echo "The size of the swap partition will be : $[partsize_swap]G"
	echo "The size of the root partition will be : $[partsize_root]G"
	echo "The size of the usr partition will be : $[partsize_usr]G"
	echo "The size of the var partition will be : $[partsize_var]G"
	echo "The size of the opt partition will be : $[partsize_opt]G"
	echo "The size of the tmp partition will be : $[partsize_tmp]G"
	echo "The size of the home partition will be : $[partsize_home]G"

echo "n
p
1

+$[partsize_boot+1]M
n
p
2

+$[partsize_swap+1]G
t
2
82
n
p
3


a
1
w
" | fdisk /dev/sda
partx --add /dev/sda1
partx --add /dev/sda3
pvcreate /dev/sda3
vgcreate vg1 /dev/sda3
lvcreate -L$[partsize_root]G -nroot vg1
lvcreate -L$[partsize_usr]G -nusr vg1
lvcreate -L$[partsize_var]G -nvar vg1
lvcreate -L$[partsize_opt]G -nopt vg1
lvcreate -L$[partsize_tmp]G -ntmp vg1
lvcreate -L$[partsize_home]G -nhome vg1

echo "Encrypting..."

for i in root tmp home usr var opt; do cryptsetup luksFormat -q -c aes-xts-plain64 -s 512 -h sha512 -y /dev/vg1/$i; done

cryptsetup create -c aes-xts-plain64 -s 512 -h sha512 -q -d /dev/urandom swap /dev/sda2
mkswap /dev/mapper/swap
swapon /dev/mapper/swap

echo "Open the containers and format with a filesystem..."
for i in root tmp home usr var opt; do cryptsetup luksOpen /dev/vg1/$i crypt$i; done
for i in root tmp home usr var opt; do mkfs.ext4 /dev/mapper/crypt$i; done
mkfs.ext3 /dev/sda1

echo "Create the mountpoints and mount your volumes..."

mount /dev/mapper/cryptroot /mnt/gentoo/
for i in tmp home usr var opt boot; do mkdir /mnt/gentoo/$i; done
mount /dev/sda1 /mnt/gentoo/boot/
for i in tmp home usr var opt; do mount /dev/mapper/crypt$i /mnt/gentoo/$i; done

echo "Preparing the chroot..."

chmod 1777 /mnt/gentoo/tmp/
cd /mnt/gentoo/
echo "Please enter the correct date in format MMDDhhmmYYYY:"
read date
date $date

wget http://de-mirror.org/gentoo/snapshots/portage-latest.tar.bz2
wget http://de-mirror.org/gentoo/releases/amd64/autobuilds/current-stage3-amd64-hardened/stage3-amd64-hardened-20140807.tar.bz2

tar xvjpf stage3-amd64* -C /mnt/gentoo
tar xvjf /mnt/gentoo/portage-latest.tar.bz2 -C /mnt/gentoo/usr

rm /mnt/gentoo/etc/portage/make.conf

cat >> /mnt/gentoo/etc/portage/make.conf<<EOF

CFLAGS="-march=native -O2 -pipe"
CXXFLAGS="${CFLAGS}"
CHOST="x86_64-pc-linux-gnu"
USE="ipv6 ssl crypt cryptsetup device-mapper lvm2 acl cracklib bindist mmx sse sse2 symlink lm_sensors -kde -selinux -gnome -X -qt3 -qt3support -qt4 -mp3"
LINGUAS="de en"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
GENTOO_MIRRORS="http://de-mirror.org/gentoo/ ftp://de-mirror.org/gentoo/ rsync://de-mirror.org/gentoo/ ftp://ftp.wh2.tu-dresden.de/pub/mirrors/gentoo http://gentoo.mneisen.org"

SYNC="rsync://rsync10.de.gentoo.org/gentoo-portage"
EOF

cp -L /etc/resolv.conf /mnt/gentoo/etc/
mount -t proc none /mnt/gentoo/proc
mount -o bind /dev /mnt/gentoo/dev

echo "Chroot into your new environment..."
chroot /mnt/gentoo/ /bin/bash

fi
