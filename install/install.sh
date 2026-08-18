#!/bin/sh
# sudo loadkeys jp106

set -eu

DISK="/dev/vda"
HOSTNAME="nix01"
# HOSTNAME="nix02"
SWAP_SIZE_GB=4

# -----------------------------------------------------------------------------
# 安全チェック
# -----------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root." >&2
    exit 1
fi

if [ ! -b "$DISK" ]; then
    echo "ERROR: $DISK does not exist." >&2
    exit 1
fi

if mount | grep -q "^${DISK}"; then
    echo "ERROR: ${DISK} or its partitions are already mounted." >&2
    exit 1
fi

if mountpoint -q /mnt; then
    echo "ERROR: /mnt is already a mountpoint." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# 実行前確認
# -----------------------------------------------------------------------------

echo ""
echo "WARNING: This will DESTROY all data on ${DISK}."
echo "  Partition layout:"
echo "    ${DISK}1  ESP   (fat32)   1MiB  - 512MiB"
echo "    ${DISK}2  root  (btrfs)   512MiB - ${SWAP_SIZE_GB}GiB from end"
echo "    ${DISK}3  swap  (linux-swap)  ${SWAP_SIZE_GB}GiB from end - 100%"
echo "  Btrfs subvolumes: @, @home, @nix, @mysql"
echo ""
printf "Are you sure you want to continue? [y/N] "
read -r confirm
case "$confirm" in
    [Yy]*) ;;
    *)
        echo "Aborted."
        exit 1
        ;;
esac

# -----------------------------------------------------------------------------
# パーティション作成
# -----------------------------------------------------------------------------

parted --script "$DISK" -- mklabel gpt
parted --script "$DISK" -- mkpart ESP fat32 1MiB 512MiB
parted --script "$DISK" -- mkpart primary 512MiB "-${SWAP_SIZE_GB}GiB"
parted --script "$DISK" -- mkpart primary linux-swap "-${SWAP_SIZE_GB}GiB" 100%
parted --script "$DISK" -- set 1 esp on

# -----------------------------------------------------------------------------
# フォーマット
# -----------------------------------------------------------------------------

mkfs.fat -F 32 -n boot "${DISK}1"
mkfs.btrfs -L nixos -f "${DISK}2"
mkswap -L swap "${DISK}3"

# -----------------------------------------------------------------------------
# サブボリューム作成
# -----------------------------------------------------------------------------

mount -t btrfs "${DISK}2" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@mysql
# MariaDB 用サブボリュームでは CoW を無効化
chattr +C /mnt/@mysql
umount /mnt

# -----------------------------------------------------------------------------
# マウント
# -----------------------------------------------------------------------------

mount -o compress=zstd,discard=async,subvol=@ "${DISK}2" /mnt
mkdir -p /mnt/{boot,home,nix,var/lib/mysql}
mount -o compress=zstd,discard=async,subvol=@home "${DISK}2" /mnt/home
mount -o compress=zstd,noatime,discard=async,subvol=@nix "${DISK}2" /mnt/nix
# MariaDB 用: CoW 無効（nodatacow）で SSD 最適化
mount -o nodatacow,discard=async,subvol=@mysql "${DISK}2" /mnt/var/lib/mysql
mount "${DISK}1" /mnt/boot
swapon "${DISK}3"

# -----------------------------------------------------------------------------
# NixOS 設定の雛形生成
# -----------------------------------------------------------------------------

nixos-generate-config --root /mnt

echo ""
echo "Finished generating /mnt/etc/nixos/configuration.nix"
echo "and /mnt/etc/nixos/hardware-configuration.nix."
echo ""
echo "Next steps:"
echo "  1. Edit the generated NixOS configuration files."
echo "  2. Enable zramSwap in configuration.nix (recommended for 2GB RAM)."
echo "  3. Run: nixos-install --root /mnt --flake .#${HOSTNAME}"

