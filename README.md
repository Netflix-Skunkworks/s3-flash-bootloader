[![Build Status](https://travis-ci.org/Netflix-Skunkworks/s3-flash-bootloader.svg?branch=master)](https://travis-ci.org/Netflix-Skunkworks/s3-flash-bootloader)

This is a minimal in-memory operating system for flashing new disk images onto
existing servers. It is especially useful for stateful services running on
cloud instances which cannot preserve ephemeral state (e.g Amazon EC2
instance-store).

This system allows you to perform in-place upgrades of a server's entire
software, producing a software configuration identical to that of a freshly
launched server image. It may either complement or entirely replace a
configuration management tool. When it replaces a configuration management
tool, it achieves many of the benefits of immutable servers, even when hardware
is long-lived.

# Prerequisites

* The existing system must have [GRUB][GRUB] installed
* The existing system cannot be running on a `PV` Virtualized AMI.
* Enough memory to store the compressed OS image.

[GRUB]: https://www.gnu.org/software/grub/

# Installing

Installing s3-flash-bootloader on your system overwrites any existing boot
configuration. After installation, your system will not be able to boot, except
into s3-flash-bootloader. For this reason there are two safety mechanism built
into the bootloader:

1. If downloading fails (permissions, image doesn't exist, etc ...) the
   bootloader will reboot back into your original OS without flashing the
   root volume.
2. You can include your public SSH keys in the bootloader so you can still SSH
   into the bootloader itself while it is running.

We publish a release tarball for [x86_64][release]. Installation of the
bootloader will depend on your environment. A minimal install script might look
like:

    #!/bin/bash
    set -e
    # Make a backup so that the bootloader can restore the machine if downloading fails
    cp -a /boot /boot.bak
    # Install the bootloader
    tar -C /boot -xvf bootloader-$(uname -m).tar.gz
    cd /boot

    # Tell the bootloader where to load the new AMI from
    /boot/configure_bootloader.sh <bucket>/<key> /dev/disk/by-label/cloudimg-rootfs
    # Add a SSH key so that you can access the bootloader while it is running
    /boot/add_ssh_key.sh ~/.ssh/id_ed25519.pub

[release]: https://github.com/Netflix-Skunkworks/s3-flash-bootloader/releases/latest/download/bootloader-x86_64.tar.gz

# Producing flashable images

s3-flash-bootloader requires lz4-compressed full disk images stored in s3.
Included in the examples directory of this repo is a script to upload the
contents of an AMI to S3. We hope this script can serve as a useful template as
you adapt it to fit your environment. At Netflix we tie similar automation into
our AMI baking piplines which upload the disk image directly to S3 in addition
to the normal snapshot and publish.

# Usage note

Most stateful services depend on caches to achieve good performance. After a
system is rebooted, it is likely that these caches will be cold, and unable to
offer appropriate performance. We recommend re-warming caches before applying
traffic to any rebooted stateful service.

 * within Netflix, we use [happycache][happycache], which works for databases
 that use the Linux page cache (e.g. Cassandra, Postgres)
 * [pgfadvise_loader][pgfincore] is available as an extension to Postgres
 * MySQL can [dump and reload][mysql-preload] its buffer pool

[happycache]: https://github.com/hashbrowncipher/happycache
[pgfincore]: https://git.postgresql.org/gitweb/?p=pgfincore.git;a=blob;f=README.md;h=e72215ec2cda0fa0b8fc0930f55588f1e09c64d6;hb=refs/heads/master
[mysql-preload]: https://dev.mysql.com/doc/refman/5.6/en/innodb-preload-buffer-pool.html

# Similar software

Many operating systems have built-in mechanisms for performing in-place
upgrades using full images, including most network-device OSes, Chromebooks,
and container OSes like Container Linux. s3-flash-bootloader uses similar
mechanisms, but intentionally does not require any integration with the OS
being booted. As a result, we are compatible with any OS image.

# Building

You may also build from source by cloning this repository and running
`./build.sh`. The build process uses debootstrap, and generally assumes a
Debian-like OS.

# Contributing

We hope this code is useful for you, and we are happy to accept bugfixes.
If you prefer to build new features we encourage you to fork and adapt this to
your needs.
