This is a minimal in-memory operating system for flashing new disk images onto
existing servers. It is especially useful for stateful services running on
cloud instances which cannot preserve ephemeral state (e.g Amazon EC2
instance-store).

This system allows you to perform in-place upgrades of a server's entire
software, producing a software configuration identical to that of a freshly
booted server. It may either complement or supplant a configuration management
tool. When it fully replaces a configuration management tool, it achieves many
of the benefits of immutable servers, even when hardware is long-lived.

# Prerequisites

* The existing system must have [GRUB][GRUB] installed

[GRUB]: https://www.gnu.org/software/grub/

# Installing

Installing s3-flash-bootloader on your system overwrites any existing boot
configuration. After installation, your system will not be able to boot, except
into s3-flash-bootloader.

We publish a release tarball for [x86_64][release]. Installation of the
bootloader will depend on your environment. A minimal install script might look
like:

    #!/bin/bash
    set -e
    cp -a /boot /boot.bak
    tar -C /boot -xvf bootloader-$(uname -m).tar.gz
    /boot/configure_bootloader.sh <bucket>/<key> /dev/disk/by-label/cloudimg-rootfs
    /boot/add_ssh_key.sh ~/.ssh/id_ed25519.pub

[release]: https://github.com/Netflix-Skunkworks/s3-flash-bootloader/releases/latest/download/bootloader-x86_64.tar.gz

# Producing flashable images

s3-flash-bootloader requires lz4-compressed full disk images stored in s3.
Included in the examples directory of this repo is a script to upload the
contents of an AMI to S3. We hope this script can serve as a useful template as
you adapt it to fit your environment

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

We hope this code is useful for you. Unfortunately we cannot take substantive
contributions at this time.
