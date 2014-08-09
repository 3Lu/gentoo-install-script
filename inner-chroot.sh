#!/bin/sh

env-update && source /etc/profile
emerge --sync
eselect profile set 11

chmod 1777 /dev/shm

rm /etc/locale.gen
cat >> /etc/locale.gen<<EOF

en_US ISO-8859-1
en_US.UTF-8 UTF-8
de_DE ISO-8859-1
de_DE@euro ISO-8859-15
de_DE.UTF-8 UTF-8
EOF

locale-gen
cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime

rm /etc/conf.d/keymaps

cat >> /etc/conf.d/keymaps<<EOF

keymap="de"
windowkeys="YES"
extended_keymaps=""
dumpkeys_charset=""
fix_euro="YES"
EOF

emerge -v hardened-sources
emerge -v genkernel cryptsetup lvm2 vim busybox
rc-update add lvm boot
rc-update add dmcrypt boot
rc-update add sshd default
# kernel configuration

cp /usr/src/linux/.config /usr/sec/linux/.config-backup
cp /usr/share/genkernel/arch/x86_64/kernel-config //usr/share/genkernel/arch/x86_64/kernel-config-backup

echo "CONFIG_CRYPTO_ABLK_HELPER=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_CRYPTO_GLUE_HELPER_X86=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_EXT2_FS_XATTR=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_EXT3_DEFAULTS_TO_ORDERED=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_EXT3_FS_XATTR=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_EXT3_FS_POSIX_ACL=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_EXT3_FS_SECURITY=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_BLK_DEV_RAM_COUNT=16" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_BLK_DEV_RAM_SIZE=16384" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_KERNEXEC_PLUGIN=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_PER_CPU_PGD=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_TASK_SIZE_MAX_SHIFT=42" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_USERCOPY_SLABS=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CONFIG_AUTO=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_CONFIG_CUSTOM is not set echo
echo "CONFIG_GRKERNSEC_CONFIG_SERVER=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_CONFIG_DESKTOP is not set echo "CONFIG_GRKERNSEC_CONFIG_VIRT_NONE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_CONFIG_VIRT_GUEST is not set # CONFIG_GRKERNSEC_CONFIG_VIRT_HOST is not set
# CONFIG_GRKERNSEC_CONFIG_PRIORITY_PERF is not echo
echo "CONFIG_GRKERNSEC_CONFIG_PRIORITY_SECURITY=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_PROC_GID=10" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_TPE_UNTRUSTED_GID=100" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_SYMLINKOWN_GID=100" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_XATTR_PAX_FLAGS=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_NOEXEC=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_PAGEEXEC=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_EMUTRAMP=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_MPROTECT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_KERNEXEC=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_KERNEXEC_PLUGIN_METHOD_BTS=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_PAX_KERNEXEC_PLUGIN_METHOD_OR is not set
echo "CONFIG_PAX_KERNEXEC_PLUGIN_METHOD="bts"" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_ASLR=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_RANDKSTACK=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_RANDUSTACK=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_RANDMMAP=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_MEMORY_SANITIZE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_MEMORY_STACKLEAK=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_MEMORY_STRUCTLEAK=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_MEMORY_UDEREF=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_REFCOUNT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_CONSTIFY_PLUGIN=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_USERCOPY=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_PAX_USERCOPY_DEBUG is not set
echo "CONFIG_PAX_SIZE_OVERFLOW=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PAX_LATENT_ENTROPY=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_KMEM=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_IO=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_PERF_HARDEN=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_RAND_THREADSTACK=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_PROC_MEMMAP=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_KSTACKOVERFLOW=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_BRUTE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_MODHARDEN=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_HIDESYM=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_RANDSTRUCT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_RANDSTRUCT_PERFORMANCE is not set
echo "CONFIG_GRKERNSEC_KERN_LOCKOUT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_ACL_HIDEKERN=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_ACL_MAXTRIES=3" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_ACL_TIMEOUT=30" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_PROC=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_PROC_USER is not set
echo "CONFIG_GRKERNSEC_PROC_USERGROUP=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_PROC_ADD=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_LINK=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_SYMLINKOWN=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_FIFO=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_SYSFS_RESTRICT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_ROFS is not set
echo "CONFIG_GRKERNSEC_DEVICE_SIDECHANNEL=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_MOUNT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_DOUBLE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_PIVOT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_CHDIR=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_CHMOD=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_FCHDIR=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_MKNOD=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_SHMAT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_UNIX=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_FINDTASK=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_NICE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_SYSCTL=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_CAPS=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_INITRD=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_EXECLOG=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_RESLOG=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_CHROOT_EXECLOG=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_AUDIT_PTRACE is not set
echo "CONFIG_GRKERNSEC_AUDIT_CHDIR=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_AUDIT_MOUNT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_SIGNAL=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_FORKFAIL=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_TIME=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_PROC_IPADDR=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_RWXMAP_LOG=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_DMESG=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_HARDEN_PTRACE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_PTRACE_READEXEC=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_SETXID=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_HARDEN_IPC=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_TPE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_TPE_ALL is not set
# CONFIG_GRKERNSEC_TPE_INVERT is not set
echo "CONFIG_GRKERNSEC_TPE_GID=100" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_RANDNET=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_BLACKHOLE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_NO_SIMULT_CONNECT=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_DENYUSB=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_DENYUSB_FORCE=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_SYSCTL=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_GRKERNSEC_SYSCTL_DISTRO is not set
echo "CONFIG_GRKERNSEC_SYSCTL_ON=y" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "# CONFIG_GRKERNSEC_SELINUX_AVC_LOG_IPADDR is not set" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_FLOODTIME=10" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_GRKERNSEC_FLOODBURST=6" >> /usr/share/genkernel/arch/x86_64/kernel-config
echo "CONFIG_PADATA=y" >> /usr/share/genkernel/arch/x86_64/kernel-config

sleep 1

sed -i s/"# CONFIG_LOCALVERSION_AUTO is not set"/CONFIG_LOCALVERSION_AUTO=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CC_OPTIMIZE_FOR_SIZE is not set"/CONFIG_CC_OPTIMIZE_FOR_SIZE=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_JUMP_LABEL is not set"/CONFIG_JUMP_LABEL=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"CONFIG_CC_STACKPROTECTOR_NONE=y"/"CONFIG_CC_STACKPROTECTOR_NONE is not set"/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"CONFIG_CC_STACKPROTECTOR is not set"/CONFIG_CC_STACKPROTECTOR=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"CONFIG_MODVERSIONS is not set"/CONFIG_MODVERSIONS=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_PREEMPT_NONE is not set"/CONFIG_PREEMPT_NONE=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"CONFIG_PREEMPT_VOLUNTARY=y"/"# CONFIG_PREEMPT_VOLUNTARY is not set"/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE is not set"/CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"CONFIG_CPU_FREQ_DEFAULT_GOV_USERSPACE=y"/"# CONFIG_CPU_FREQ_DEFAULT_GOV_USERSPACE is not set"/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_BLK_DEV_CRYPTOLOOP is not set"/CONFIG_BLK_DEV_CRYPTOLOOP=y/ /usr/share/genkernel/arch/x86_64/kernel-config
# CONFIG_EXT4_DEBUG is not set"/CONFIG_EXT4_DEBUG=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_JBD2_DEBUG is not set"/CONFIG_JBD2_DEBUG=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_STRICT_DEVMEM is not set"/CONFIG_STRICT_DEVMEM=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_DEBUG_LIST is not set"/CONFIG_DEBUG_LIST=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_BLK_DEV_CRYPTOLOOP is not set"/CONFIG_BLK_DEV_CRYPTOLOOP=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_DM_DEBUG is not set"/CONFIG_DM_DEBUG=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_DM_CRYPT is not set"/CONFIG_DM_CRYPT=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"CONFIG_USB_MON=y"/"# CONFIG_USB_MON is not set"/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"CONFIG_USB_PRINTER=y"/"# CONFIG_USB_PRINTER is not set"/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_EXT2_FS is not set"/CONFIG_EXT2_FS=m/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_EXT3_FS is not set"/CONFIG_EXT3_FS=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_BLK_DEV_RAM is not set"/CONFIG_BLK_DEV_RAM=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_AES_X86_64 is not set"/CONFIG_CRYPTO_AES_X86_64=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_GF128MUL is not set"/CONFIG_CRYPTO_GF128MUL=y/  /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_NULL is not set"/CONFIG_CRYPTO_NULL=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_PCRYPT is not set"/CONFIG_CRYPTO_PCRYPT=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_CRYPTD is not set"/CONFIG_CRYPTO_CRYPTD=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_CTS is not set"/CONFIG_CRYPTO_CTS=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_LRW is not set"/CONFIG_CRYPTO_LRW=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_XTS is not set"/CONFIG_CRYPTO_XTS=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_AES_NI_INTEL is not set"/CONFIG_CRYPTO_AES_NI_INTEL=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_SHA1_SSSE3 is not set"/CONFIG_CRYPTO_SHA1_SSSE3=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_SHA256_SSSE3 is not set"/CONFIG_CRYPTO_SHA256_SSSE3=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_SHA512_SSSE3 is not set"/CONFIG_CRYPTO_SHA512_SSSE3=y/ /usr/share/genkernel/arch/x86_64/kernel-config
sed -i s/"# CONFIG_CRYPTO_SHA512 is not set"/CONFIG_CRYPTO_SHA512=y/ /usr/share/genkernel/arch/x86_64/kernel-config

echo "Compile your own kernel..."

genkernel --no-menuconfig --lvm --luks --disklabel --clean --install --all-ramdisk-modules all

for module in `find /lib/modules/3.15.5-hardened-r2/ -type f -iname '*.o' -or -iname '*.ko' | awk --field-separator "/" {'print $NF'} | sed s/.ko//`; do echo "modules_2_6=\"$module\"" >> /etc/conf.d/modules; done

rm /etc/fstab

cat >>/etc/fstab<<EOF

/dev/sda1	 	/boot		ext3		noauto,noatime	1 2
/dev/mapper/swap	none		swap		sw		0 0
/dev/mapper/cryptroot	/		ext4		nodev,noatime	0 0
/dev/mapper/crypthome	/home		ext4		nodev,noexec,nosuid,noatime	0 1
/dev/mapper/crypttmp	/tmp		ext4		nodev,noexec,noatime		0 2
/dev/mapper/cryptusr 	/usr 		ext4		nodev,noatime	0 2
/dev/mapper/cryptvar 	/var		ext4		nodev,noexec,noatime		0 2
/dev/mapper/cryptopt 	/opt 		ext4		nodev,noexec,nosuid,noatime 0 2
shm 			/dev/shm 	tmpfs 		nodev,nosuid,noexec		0 0
EOF
#bug
echo "Please enter your hostname:"
read hostname

echo "hostname=\"$[$hostname]\"" > /etc/conf.d/hostname
#bug end
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
grub2-install /dev/sda
echo "GRUB_PRELOAD_MODULES=lvm" >> /etc/default/grub
echo "GRUB_CRYPTODISK_ENABLE=y" >> /etc/default/grub
sed -i s/"root=${linux_root_device_thisversion}"/"dolvm rootfstype=ext4 crypt_root=${linux_root_device_thisversion}"/ /etc/grub.d/10_linux
grub2-mkconfig -o /boot/grub/grub.cfg

rm /etc/conf.d/dmcrypt
cat >> /etc/conf.d/dmcrypt<<EOF

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
emerge -na =sys-apps/gradm-3.0*
echo "Now the installation is finished. Have fun! Don't forget to add a non-root user!!"
sleep 30

reboot