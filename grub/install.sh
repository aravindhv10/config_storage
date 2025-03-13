#!/bin/sh
cd "$('dirname' -- "${0}")"

grub-install \
    "--boot-directory=$('realpath' .)" \
    "--efi-directory=$('realpath' .)" \
    '--removable' \
    '--target=x86_64-efi' \
    '/dev/nvme0n1' \
;

exit '0'

Usage: grub-install [OPTION...] [OPTION] [INSTALL_DEVICE]
Install GRUB on your drive.

      --compress=no|xz|gz|lzo   compress GRUB files [optional]
      --disable-shim-lock    disable shim_lock verifier
      --dtb=FILE             embed a specific DTB
  -d, --directory=DIR        use images and modules under DIR
                             [default=/nix/store/221007bg7hkfkdwy6wgc0axhidcmypis-grub-2.12/lib/grub/<platform>]
      --fonts=FONTS          install FONTS [default=unicode]
      --install-modules=MODULES   install only MODULES and their dependencies
                             [default=all]
  -k, --pubkey=FILE          embed FILE as public key for signature checking
      --locale-directory=DIR use translations under DIR
                             [default=/nix/store/221007bg7hkfkdwy6wgc0axhidcmypis-grub-2.12/share/locale]
      --locales=LOCALES      install only LOCALES [default=all]
      --modules=MODULES      pre-load specified modules MODULES
      --sbat=FILE            SBAT metadata
      --themes=THEMES        install THEMES [default=starfield]
  -v, --verbose              print verbose messages.
      --allow-floppy         make the drive also bootable as floppy (default
                             for fdX devices). May break on some BIOSes.
      --boot-directory=DIR   install GRUB images under the directory DIR/grub
                             instead of the boot/grub directory
      --bootloader-id=ID     the ID of bootloader. This option is only
                             available on EFI and Macs.
      --core-compress=xz|none|auto
                             choose the compression to use for core image
      --disk-module=MODULE   disk module to use (biosdisk or native). This
                             option is only available on BIOS target.
      --efi-directory=DIR    use DIR as the EFI System Partition root.
      --force                install even if problems are detected
      --force-file-id        use identifier file even if UUID is available
      --label-bgcolor=COLOR  use COLOR for label background
      --label-color=COLOR    use COLOR for label
      --label-font=FILE      use FILE as font for label
      --macppc-directory=DIR use DIR for PPC MAC install.
      --no-bootsector        do not install bootsector
      --no-nvram             don't update the `boot-device'/`Boot*' NVRAM
                             variables. This option is only available on EFI
                             and IEEE1275 targets.
      --no-rs-codes          Do not apply any reed-solomon codes when
                             embedding core.img. This option is only available
                             on x86 BIOS targets.
      --product-version=STRING   use STRING as product version
      --recheck              delete device map if it already exists
      --removable            the installation device is removable. This option
                             is only available on EFI.
  -s, --skip-fs-probe        do not probe for filesystems in DEVICE
      --target=TARGET        install GRUB for TARGET platform
                             [default=x86_64-efi]; available targets:
                             arm-coreboot, arm-efi, arm-uboot, arm64-efi,
                             i386-coreboot, i386-efi, i386-ieee1275,
                             i386-multiboot, i386-pc, i386-qemu, i386-xen,
                             i386-xen_pvh, ia64-efi, loongarch64-efi,
                             mips-arc, mips-qemu_mips, mipsel-arc,
                             mipsel-loongson, mipsel-qemu_mips,
                             powerpc-ieee1275, riscv32-efi, riscv64-efi,
                             sparc64-ieee1275, x86_64-efi, x86_64-xen
  -?, --help                 give this help list
      --usage                give a short usage message
  -V, --version              print program version

Mandatory or optional arguments to long options are also mandatory or optional
for any corresponding short options.

INSTALL_DEVICE must be system device filename.
grub-install copies GRUB images into boot/grub.  On some platforms, it may
also install GRUB into the boot sector.

Report bugs to <bug-grub@gnu.org>.
