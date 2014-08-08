#!/bin/bash


echo "ATTENTION!!!! BATCH Mode active!!! All data on selected device will be lost"
echo "Please configure your network manually!"
echo "You can start a sshd server by '/etc/init.d/sshd start'"
echo "Setup a new root password with 'passwd root'. This is your SSH-Login-Password"

echo "Do you want to proceed (y or N)?"
read answer
if [ $answer == "y" ]; then
	"Loading necessary kernel modules..."
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

# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.
CFLAGS="-march=native -O2 -pipe"
CXXFLAGS="${CFLAGS}"
# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult http://www.gentoo.org/doc/en/change-chost.xml before
changing.
CHOST="x86_64-pc-linux-gnu"
# These are the USE flags that were used in addition to what is provided
by the
# profile used for building.
USE="ipv6 ssl crypt cryptsetup device-mapper lvm2 acl cracklib bindist mmx sse sse2 symlink lm_sensors -kde -selinux -gnome -X -qt3 -qt3support -qt4 -mp3"
LINGUAS="de en"
PORTDIR="/usr/portage"
DISTDIR="${PORTDIR}/distfiles"
PKGDIR="${PORTDIR}/packages"
GENTOO_MIRRORS="http://de-mirror.org/gentoo/ ftp://de-mirror.org/gentoo/ rsync://de-mirror.org/gentoo/ ftp://ftp.wh2.tu-dresden.de/pub/mirrors/gentoo http://gentoo.mneisen.org

SYNC="rsync://rsync10.de.gentoo.org/gentoo-portage"
EOF

cp -L /etc/resolv.conf /mnt/gentoo/etc/
mount -t proc none /mnt/gentoo/proc
mount -o bind /dev /mnt/gentoo/dev

echo "Chroot into your new environment..."
chroot /mnt/gentoo/ /bin/bash
env-update && source /etc/profile
emerge --sync
eselect profile set 11

#Bugfix!
chmod 1777 /dev/shm

rm /etc/locale.gen
cat >> /etc/locale.gen<<EOF

GNU nano 2.3.2 File:
/etc/locale.gen

# /etc/locale.gen: list all of the locales you want to have on your system
#
# The format of each line:
# <locale> <charmap>
#
# Where <locale> is a locale located in /usr/share/i18n/locales/ and
# where <charmap> is a charmap located in /usr/share/i18n/charmaps/.
#
# All blank lines and lines starting with # are ignored.
#
# For the default list of supported combinations, see the file:
# /usr/share/i18n/SUPPORTED
#
# Whenever glibc is emerged, the locales listed here will be automatically
# rebuilt for you. Â After updating this file, you can simply run `locale-gen`
# yourself instead of re-emerging glibc.

en_US ISO-8859-1
en_US.UTF-8 UTF-8
#ja_JP.EUC-JP EUC-JP
#ja_JP.UTF-8 UTF-8
#ja_JP EUC-JP
#en_HK ISO-8859-1
#en_PH ISO-8859-1
de_DE ISO-8859-1
de_DE@euro ISO-8859-15
de_DE.UTF-8 UTF-8
#es_MX ISO-8859-1
#fa_IR UTF-8
#fr_FR ISO-8859-1
#fr_FR@euro ISO-8859-15
#it_IT ISO-8859-1
EOF

locale-gen
cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime

rm /etc/conf.d/keymaps

cat >>/etc/conf.d/keymaps<<EOF

# Use keymap to specify the default console keymap. Â There is a complete tree
# of keymaps in /usr/share/keymaps to choose from.
keymap="de"

# Should we first load the 'windowkeys' console keymap? Â Most x86 users will
# say "yes" here. Â Note that non-x86 users should leave it as "no".
# Loading this keymap will enable VT switching (like ALT+Left/Right)
# using the special windows keys on the linux console.
windowkeys="YES"

# The maps to load for extended keyboards. Â Most users will leave this as is.
extended_keymaps=""
#extended_keymaps="backspace keypad euro2"

# Tell dumpkeys(1) to interpret character action codes to be
# from the specified character set.
# This only matters if you set unicode="yes" in /etc/rc.conf.
# For a list of valid sets, run `dumpkeys --help`
dumpkeys_charset=""

# Some fonts map AltGr-E to the currency symbol Â¤ instead of the Euro â¬
# To fix this, set to "yes"
fix_euro="YES"
EOF

emerge -v hardened-sources
emerge -v genkernel cryptsetup lvm2 vim busybox
rc-update add lvm boot
rc-update add dmcrypt boot
rc-update add sshd default
# kernel configuration

sed -i s/"# CONFIG_LOCALVERSION_AUTO is not set"/CONFIG_LOCALVERSION_AUTO=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CC_OPTIMIZE_FOR_SIZE is not set"/CONFIG_CC_OPTIMIZE_FOR_SIZE=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_JUMP_LABEL is not set"/CONFIG_JUMP_LABEL=y/ /usr/src/linux/.config
sed -i s/"CONFIG_CC_STACKPROTECTOR_NONE=y"/"CONFIG_CC_STACKPROTECTOR_NONE is not set"/ /usr/src/linux/.config
sed -i s/"CONFIG_CC_STACKPROTECTOR is not set"/CONFIG_CC_STACKPROTECTOR=y/ /usr/src/linux/.config
#sed -i s/"CONFIG_CC_STACKPROTECTOR_STRONG is not set"/CONFIG_CC_STACKPROTECTOR_STRONG=y/ /usr/src/linux/.config
sed -i s/"CONFIG_MODVERSIONS is not set"/CONFIG_MODVERSIONS=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_PREEMPT_NONE is not set"/CONFIG_PREEMPT_NONE=y/ /usr/src/linux/.config
sed -i s/"CONFIG_PREEMPT_VOLUNTARY=y"/"# CONFIG_PREEMPT_VOLUNTARY is not set"/ /usr/src/linux/.config
sed -i s/"# CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE is not set"/CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y/ /usr/src/linux/.config
sed -i s/"CONFIG_CPU_FREQ_DEFAULT_GOV_USERSPACE=y"/"# CONFIG_CPU_FREQ_DEFAULT_GOV_USERSPACE is not set"/ /usr/src/linux/.config
sed -i s/"# CONFIG_BLK_DEV_CRYPTOLOOP is not set"/CONFIG_BLK_DEV_CRYPTOLOOP=y/ /usr/src/linux/.config
echo "CONFIG_BLK_DEV_RAM_COUNT=16" >> /usr/src/linux/.config
echo "CONFIG_BLK_DEV_RAM_SIZE=16384" >> /usr/src/linux/.config
sed -i s/"# CONFIG_DM_DEBUG is not set"/CONFIG_DM_DEBUG=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_DM_CRYPT is not set"/CONFIG_DM_CRYPT=y/ /usr/src/linux/.config
sed -i s/"CONFIG_USB_MON=y"/"# CONFIG_USB_MON is not set"/ /usr/src/linux/.config
sed -i s/"CONFIG_USB_PRINTER=y"/"# CONFIG_USB_PRINTER is not set"/ /usr/src/linux/.config
sed -i s/"# CONFIG_EXT2_FS is not set"/CONFIG_EXT2_FS=m/ /usr/src/linux/.config
sed -i s/"# CONFIG_EXT3_FS is not set"/CONFIG_EXT3_FS=y/ /usr/src/linux/.config
echo "CONFIG_EXT2_FS_XATTR=y" >> /usr/src/linux/.config
echo "CONFIG_EXT3_DEFAULTS_TO_ORDERED=y" >> /usr/src/linux/.config
echo "CONFIG_EXT3_FS_XATTR=y" >> /usr/src/linux/.config
echo "CONFIG_EXT3_FS_POSIX_ACL=y" >> /usr/src/linux/.config
echo "CONFIG_EXT3_FS_SECURITY=y" >> /usr/src/linux/.config
sed -i s/"# CONFIG_EXT4_DEBUG is not set"/CONFIG_EXT4_DEBUG=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_JBD2_DEBUG is not set"/CONFIG_JBD2_DEBUG=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_STRICT_DEVMEM is not set"/CONFIG_STRICT_DEVMEM=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_DEBUG_LIST is not set"/CONFIG_DEBUG_LIST=y/ /usr/src/linux/.config
echo "CONFIG_PAX_KERNEXEC_PLUGIN=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_PER_CPU_PGD=y" >> /usr/src/linux/.config
echo "CONFIG_TASK_SIZE_MAX_SHIFT=42" >> /usr/src/linux/.config
echo "CONFIG_PAX_USERCOPY_SLABS=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CONFIG_AUTO=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_CONFIG_CUSTOM is not set echo "CONFIG_GRKERNSEC_CONFIG_SERVER=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_CONFIG_DESKTOP is not set echo "CONFIG_GRKERNSEC_CONFIG_VIRT_NONE=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_CONFIG_VIRT_GUEST is not set # CONFIG_GRKERNSEC_CONFIG_VIRT_HOST is not set
# CONFIG_GRKERNSEC_CONFIG_PRIORITY_PERF is not echo "CONFIG_GRKERNSEC_CONFIG_PRIORITY_SECURITY=y" >> /usr/src/linux/.config

#
# Default Special Groups
#
echo "CONFIG_GRKERNSEC_PROC_GID=10" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_TPE_UNTRUSTED_GID=100" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_SYMLINKOWN_GID=100" >> /usr/src/linux/.config

#
# Customize Configuration
#

#
# PaX
#
echo "CONFIG_PAX=y" >> /usr/src/linux/.config

#
# PaX Control
#
# CONFIG_PAX_SOFTMODE is not set echo "CONFIG_PAX_PT_PAX_FLAGS=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_XATTR_PAX_FLAGS=y" >> /usr/src/linux/.config
# CONFIG_PAX_NO_ACL_FLAGS is not set echo "CONFIG_PAX_HAVE_ACL_FLAGS=y" >> /usr/src/linux/.config
# CONFIG_PAX_HOOK_ACL_FLAGS is not set 
#
# Non-executable pages
#
echo "CONFIG_PAX_NOEXEC=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_PAGEEXEC=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_EMUTRAMP=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_MPROTECT=y" >> /usr/src/linux/.config
# CONFIG_PAX_MPROTECT_COMPAT is not set 
# CONFIG_PAX_ELFRELOCS is not set
echo "CONFIG_PAX_KERNEXEC=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_KERNEXEC_PLUGIN_METHOD_BTS=y" >> /usr/src/linux/.config
# CONFIG_PAX_KERNEXEC_PLUGIN_METHOD_OR is not set 
echo "CONFIG_PAX_KERNEXEC_PLUGIN_METHOD="bts"" >> /usr/src/linux/.config

#
# Address Space Layout Randomization
#
echo "CONFIG_PAX_ASLR=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_RANDKSTACK=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_RANDUSTACK=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_RANDMMAP=y" >> /usr/src/linux/.config

#
# Miscellaneous hardening features
#
echo "CONFIG_PAX_MEMORY_SANITIZE=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_MEMORY_STACKLEAK=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_MEMORY_STRUCTLEAK=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_MEMORY_UDEREF=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_REFCOUNT=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_CONSTIFY_PLUGIN=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_USERCOPY=y" >> /usr/src/linux/.config
# CONFIG_PAX_USERCOPY_DEBUG is not set
echo "CONFIG_PAX_SIZE_OVERFLOW=y" >> /usr/src/linux/.config
echo "CONFIG_PAX_LATENT_ENTROPY=y" >> /usr/src/linux/.config

#
# Memory Protections
#
echo "CONFIG_GRKERNSEC_KMEM=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_IO=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_PERF_HARDEN=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_RAND_THREADSTACK=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_PROC_MEMMAP=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_KSTACKOVERFLOW=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_BRUTE=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_MODHARDEN=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_HIDESYM=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_RANDSTRUCT=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_RANDSTRUCT_PERFORMANCE is not set
echo "CONFIG_GRKERNSEC_KERN_LOCKOUT=y" >> /usr/src/linux/.config

#
# Role Based Access Control Options
#
# CONFIG_GRKERNSEC_NO_RBAC is not set
echo "CONFIG_GRKERNSEC_ACL_HIDEKERN=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_ACL_MAXTRIES=3" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_ACL_TIMEOUT=30" >> /usr/src/linux/.config

#
# Filesystem Protections
#
echo "CONFIG_GRKERNSEC_PROC=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_PROC_USER is not set
echo "CONFIG_GRKERNSEC_PROC_USERGROUP=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_PROC_ADD=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_LINK=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_SYMLINKOWN=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_FIFO=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_SYSFS_RESTRICT=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_ROFS is not set
echo "CONFIG_GRKERNSEC_DEVICE_SIDECHANNEL=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_MOUNT=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_DOUBLE=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_PIVOT=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_CHDIR=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_CHMOD=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_FCHDIR=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_MKNOD=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_SHMAT=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_UNIX=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_FINDTASK=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_NICE=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_SYSCTL=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_CAPS=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_INITRD=y" >> /usr/src/linux/.config

#
# Kernel Auditing
#
# CONFIG_GRKERNSEC_AUDIT_GROUP is not set
echo "CONFIG_GRKERNSEC_EXECLOG=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_RESLOG=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_CHROOT_EXECLOG=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_AUDIT_PTRACE is not set
echo "CONFIG_GRKERNSEC_AUDIT_CHDIR=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_AUDIT_MOUNT=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_SIGNAL=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_FORKFAIL=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_TIME=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_PROC_IPADDR=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_RWXMAP_LOG=y" >> /usr/src/linux/.config

#
# Executable Protections
#
echo "CONFIG_GRKERNSEC_DMESG=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_HARDEN_PTRACE=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_PTRACE_READEXEC=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_SETXID=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_HARDEN_IPC=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_TPE=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_TPE_ALL is not set
# CONFIG_GRKERNSEC_TPE_INVERT is not set
echo "CONFIG_GRKERNSEC_TPE_GID=100" >> /usr/src/linux/.config

#
# Network Protections
#
echo "CONFIG_GRKERNSEC_RANDNET=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_BLACKHOLE=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_NO_SIMULT_CONNECT=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_SOCKET is not set

#
# Physical Protections
#
echo "CONFIG_GRKERNSEC_DENYUSB=y" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_DENYUSB_FORCE=y" >> /usr/src/linux/.config

#
# Sysctl Support
#
echo "CONFIG_GRKERNSEC_SYSCTL=y" >> /usr/src/linux/.config
# CONFIG_GRKERNSEC_SYSCTL_DISTRO is not set
echo "CONFIG_GRKERNSEC_SYSCTL_ON=y" >> /usr/src/linux/.config

#
# Logging Options
#
echo "# CONFIG_GRKERNSEC_SELINUX_AVC_LOG_IPADDR is not set" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_FLOODTIME=10" >> /usr/src/linux/.config
echo "CONFIG_GRKERNSEC_FLOODBURST=6" >> /usr/src/linux/.config
echo "CONFIG_PADATA=y" >> /usr/src/linux/.config
sed -i s/"# CONFIG_BLK_DEV_RAM is not set"/CONFIG_BLK_DEV_RAM=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_AES_X86_64 is not set"/CONFIG_CRYPTO_AES_X86_64=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_GF128MUL is not set"/CONFIG_CRYPTO_GF128MUL=y/  usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_NULL is not set"/CONFIG_CRYPTO_NULL=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_PCRYPT is not set"/CONFIG_CRYPTO_PCRYPT=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_CRYPTD is not set"/CONFIG_CRYPTO_CRYPTD=y/ /usr/src/linux/.config
echo "CONFIG_CRYPTO_ABLK_HELPER=y" >> /usr/src/linux/.config
echo "CONFIG_CRYPTO_GLUE_HELPER_X86=y" >> /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_CTS is not set"/CONFIG_CRYPTO_CTS=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_LRW is not set"/CONFIG_CRYPTO_LRW=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_XTS is not set"/CONFIG_CRYPTO_XTS=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_AES_NI_INTEL is not set"/CONFIG_CRYPTO_AES_NI_INTEL=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_SHA1_SSSE3 is not set"/CONFIG_CRYPTO_SHA1_SSSE3=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_SHA256_SSSE3 is not set"/CONFIG_CRYPTO_SHA256_SSSE3=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_SHA512_SSSE3 is not set"/CONFIG_CRYPTO_SHA512_SSSE3=y/ /usr/src/linux/.config
sed -i s/"# CONFIG_CRYPTO_SHA512 is not set"/CONFIG_CRYPTO_SHA512=y/ /usr/src/linux/.config

echo "Compile your own kernel..."
cp /usr/src/linux/.config /usr/share/genkernel/arch/x86_64/kernel-config

genkernel --no-menuconfig --lvm --luks --disklabel --clean --install --all-ramdisk-modules all

for module in `find /lib/modules/3.15.5-hardened-r2/ -type f -iname '*.o' -or -iname '*.ko' | awk --field-separator "/" {'print $NF'} | sed s/.ko//`; do echo "modules_2_6=\"$module\"" >> /etc/conf.d/modules; done

rm /etc/fstab

cat >>/etc/fstab<<EOF

# /etc/fstab: static file system information.
#
# noatime turns off atimes for increased performance (atimes normall aren't
# needed); notail increases performance of ReiserFS (at the expense of storage
# efficiency).It's safe to drop the noatime options if you want and to
# switch between notail / tail freely.
#
# The root filesystem should have a pass number of either 0 or 1.
# All other filesystems should have a pass number of 0 or greater than 1.
#
# See the manpage fstab(5) for more information.
#

# <fs>			<mountpoint>	<type>		<opts>		<dump/pass>
/dev/sda1	 	/boot		ext3		noauto,noatime	1 2
/dev/mapper/swap	none		swap		sw		0 0
/dev/mapper/cryptroot	/		ext4		nodev,noatime	0 0
/dev/mapper/crypthome	/home		ext4		nodev,noexec,nosuid,noatime	0 1
/dev/mapper/crypttmp	/tmp		ext4		nodev,noexec,noatime		0 2
/dev/mapper/cryptusr 	/usr 		ext4		nodev,noatime	0 2
/dev/mapper/cryptvar 	/var		ext4		nodev,noexec,noatime		 0 2
/dev/mapper/cryptopt 	/opt 		ext4		nodev,noexec,nosuid,noatime	 0 2

shm 			/dev/shm 	tmpfs 		nodev,nosuid,noexec		0 0
EOF

echo "Please enter your hostname:"
read hostname

sed -i s/localhost/$hostname/ /etc/conf.d/hostname

echo "Please enter your new root password:"
passwd root

echo "Installing Bootlader and additional software..."

emerge -v grub syslog-ng logrotate pciutils gentoolkit
rc-update add syslog-ng default

echo "If you have problems to install grub? (y/n) "
read answer
if [ $answer == "y" ]; then
	emerge -v dev-perl/Locale-gettext
	emerge -v grub
	echo "I hope it's working now?! If not, break up here and fix it manually!"
fi

#world update
emerge --update --deep --with-bdeps=y --newuse world
emerge --depclean

# Create mtab
echo "Creating mtab..."
grep -v rootfs /proc/mounts > /etc/mtab

#Make grub lvm ready
echo "GRUB_PRELOAD_MODULES=lvm" >> /etc/default/grub
echo "GRUB_CRYPTODISK_ENABLE=y" >> /etc/default/grub
sed -i s/"root=${linux_root_device_thisversion}"/"dolvm crypt_root=${linux_root_device_thisversion}"/ /etc/grub.d/10_linux 
grub2-mkconfig -o /boot/grub/grub.cfg

rm /etc/conf.d/dmcrypt
cat >>/etc/conf.d/dmcrypt<<EOF

# /etc/conf.d/dmcrypt

# For people who run dmcrypt on top of some other layer (like raid),
# use rc_need to specify that requirement. See the runscript(8) man
# page for more information.

#--------------------
# Instructions
#--------------------

# Note regarding the syntax of this file. Â This file is *almost* bash,
# but each line is evaluated separately. Â Separate swaps/targets can be
# specified. Â The init-script which reads this file assumes that a
# swap= or target= line starts a new section, similar to lilo or grub
# configuration.

# Note when using gpg keys and /usr on a separate partition, you will
# have to copy /usr/bin/gpg to /bin/gpg so that it will work properly
# and ensure that gpg has been compiled statically.
# See http://bugs.gentoo.org/90482 for more information.

# Note that the init-script which reads this file detects whether your
# partition is LUKS or not. No mkfs is run unless you specify a makefs
# option.

# Global options:
#----------------

# Max number of checks to perform (1 per second)
#dmcrypt_max_timeout=120

# Arguments:
#-----------
# target=<name> Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â == Mapping name for partition.
# swap=<name> Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â == Mapping name for swap partition.
# source='<dev>' Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â == Real device for partition.
# key='</path/to/keyfile>[:<mode>]' Â == Fullpath from / or from inside removable media.
# remdev='<dev>' Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â == Device that will be assigned to removable media.
# gpg_options='<opts>' Â Â Â Â Â Â Â Â Â Â Â Â Â Â == Default are --quiet --decrypt
# options='<opts>' Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â == cryptsetup, for LUKS you can only use --readonly
# loop_file='<file>' Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â == Loopback file.
# pre_mount='cmds' Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â == commands to execute before mounting partition.
# post_mount='cmds' == commands to execute after mounting partition.
#-----------
# Supported Modes
# gpg					== decrypt and pipe key into cryptsetup.
#						Note: new-line character must not be part of key.
#						Command to erase \n char: 'cat key | tr -d '\n' > cleanKey'

#--------------------
# dm-crypt examples
#--------------------

## swap
# Swap partitions. These should come first so that no keys make their
# way into unencrypted swap.
# If no options are given, they will default to: -c aes -h sha1 -d /dev/urandom
# If no makefs is given then mkswap will be assumed
#swap=crypt-swap
#source='/dev/hda2'

## /home with passphrase
#target=crypt-home
#source='/dev/hda5'

## /home with regular keyfile
#target=crypt-home
#source='/dev/hda5'
#key='/full/path/to/homekey'

## /home with gpg protected key
#target=crypt-home
#source='/dev/hda5'
#key='/full/path/to/homekey:gpg'

## /home with regular keyfile on removable media(such as usb-stick)
#target=crypt-home
#source='/dev/hda5'
#key='/full/path/to/homekey'
#remdev='/dev/sda1'

##/home with gpg protected key on removable media(such as usb-stick)
#target=crypt-home
#source='/dev/hda5'
#key='/full/path/to/homekey:gpg'
#remdev='/dev/sda1'

##/tmp with regular keyfile
#target=crypt-tmp
#source='/dev/hda6'
#key='/full/path/to/tmpkey'
#pre_mount='/sbin/mkreiserfs -f -f ${dev}'
#post_mount='chown root:root ${mount_point}; chmod 1777 ${mount_point}'

## Loopback file example
#mount='crypt-loop-home'
#source='/dev/loop0'
#loop_file='/mnt/crypt/home'

## /home with regular keyfile
target=crypthome
source='/dev/mapper/vg1-home'
key='/root/hdpw'

## /swap with regular keyfile
target=swap
source='/dev/sda2'
options='-c aes-xts-plain64 -s 512 -h sha512 -q -d /dev/urandom'

## /tmp with regular keyfile
target=crypttmp
source='/dev/mapper/vg1-tmp'
key='/root/hdpw'

## /usr with regular keyfile
target=cryptusr
source='/dev/mapper/vg1-usr'
key='/root/hdpw'

## /var with regular keyfile
target=cryptvar
source='/dev/mapper/vg1-var'
key='/root/hdpw'

## /opt with regular keyfile
target=cryptopt
source='/dev/mapper/vg1-opt'
key='/root/hdpw'
EOF

echo "Are you paranoid? (y/n)"
read answer
if [ $answer == "y" ]; then
	echo "I hope you have a lot of entropy...generating 4096-bit-random-keyfile...it can take a loong time!! read paper,drink coffee, love your wife and maybe then it's finish, maybe ;-) but psst i don't think so ;-)"
	dd if=/dev/random of=/root/hdpw bs=1 count=4096
else
	echo "generating 512--bit-random-keyfile..."
	dd if=/dev/random of=/root/hdpw bs=1 count=512
fi

chmod 400 /root/hdpw

for i in home tmp var usr opt; do cryptsetup luksAddKey /dev/vg1/$i /root/hdpw; done

echo "Now the installation is finished. Have fun! Don't forget to add a non-root user!!"
sleep 30

reboot
fi
