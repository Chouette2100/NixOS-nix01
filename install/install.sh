#!/bin/sh
# sudo loadkeys jp106

set -e

DISK="/dev/vda"
HOSTNAME="nix01"
# HOSTNAME="nix02"

# パーティション作成
parted $DISK -- mklabel gpt
parted $DISK -- mkpart primary 512MiB -8GiB
parted $DISK -- mkpart primary linux-swap -8GiB 100%
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 3 esp on

# フォーマット
mkfs.fat -F 32 -n boot ${DISK}3
mkfs.btrfs -L nixos ${DISK}1
mkswap -L swap ${DISK}2

# サブボリューム作成
mount -t btrfs ${DISK}1 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt

# mariadbのストレージ用サブボリューム
# mariadbのストレージのディレクトリーはどこ？
#

# マウント（圧縮有効）
mount -o compress=zstd,subvol=@ ${DISK}1 /mnt
mkdir -p /mnt/{boot,home,nix}
mount -o compress=zstd,subvol=@home ${DISK}1 /mnt/home
mount -o compress=zstd,noatime,subvol=@nix ${DISK}1 /mnt/nix
mount ${DISK}3 /mnt/boot
swapon ${DISK}2

# mariadbのストレージ用サブボリュームはcowを使わない



# 設定生成
nixos-generate-config --root /mnt

# NixOSインストール
nixos-install --root /mnt --flake .#$HOSTNAME




