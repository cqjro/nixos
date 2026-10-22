#!/usr/bin/env bash
# Provision the pinned WayDroid-ATV images on GOD-KILLER.
#
# Usage:  sudo ./waydroid-atv-install.sh [--system <zip>] [--vendor <zip>]
#
# Defaults come from the prefetch pins in docs/waydroid/:
#   .prefetch-system.json         (GAPPS system)
#   .prefetch-system-vanilla.json (VANILLA system)
#   .prefetch-vendor.json         (MAINLINE vendor)
#
# Why this is a script and not a one-liner:
#   * `waydroid init -f` must NOT see an existing-but-empty
#     /etc/waydroid-extra/images (Waydroid 1.6.3 initializer.py:55 raises
#     FileNotFoundError instead of falling through), so the directory is
#     removed and recreated, never emptied in place.
#   * `waydroid init -f` regenerates waydroid_base.prop, so the ATV
#     bt_remote_pairing property has to be appended *after* init.
#   * `sudo echo ... >> file` fails (the redirection is unprivileged);
#     `tee -a` is required.

set -euo pipefail

system_zip="/nix/store/0mir7hkikihy37ffg63rlyc3h1qnc7vx-lineage-24.0-20261017-GAPPS-waydroid_x86_64-system.zip"
vendor_zip="/nix/store/0qx3pqpfbxaszss4ly0c8zgv87mzpbr9-lineage-24.0-20261017-MAINLINE-waydroid_x86_64-vendor.zip"

while [ $# -gt 0 ]; do
	case "$1" in
		--system) system_zip="$2"; shift 2 ;;
		--vendor) vendor_zip="$2"; shift 2 ;;
		-h|--help) sed -n '2,17p' "$0"; exit 0 ;;
		*) echo "unknown argument: $1" >&2; exit 2 ;;
	esac
done

if [ "$(id -u)" -ne 0 ]; then
	echo "must run as root (sudo)" >&2
	exit 1
fi

for f in "$system_zip" "$vendor_zip"; do
	[ -f "$f" ] || { echo "missing store path: $f" >&2; exit 1; }
done

echo "==> stopping waydroid-container"
systemctl stop waydroid-container 2>/dev/null || true

# Remove the *directory*, not just its contents -- see header comment.
echo "==> clearing previous images and userdata"
rm -rf /etc/waydroid-extra
rm -rf /var/lib/waydroid/overlay /var/lib/waydroid/overlay_rw /var/lib/waydroid/overlay_work
rm -f /var/lib/waydroid/userdata.img

echo "==> extracting images"
mkdir -p /etc/waydroid-extra/images
unzip -o "$system_zip" -d /etc/waydroid-extra/images
unzip -o "$vendor_zip" -d /etc/waydroid-extra/images
ls -lh /etc/waydroid-extra/images

echo "==> waydroid init -f"
waydroid init -f

echo "==> disabling ATV bluetooth-remote pairing wizard (container has no BT)"
if ! grep -q "atv.setup.bt_remote_pairing" /var/lib/waydroid/waydroid_base.prop; then
	echo "atv.setup.bt_remote_pairing=false" | tee -a /var/lib/waydroid/waydroid_base.prop >/dev/null
fi

echo "==> starting waydroid-container"
systemctl start waydroid-container
sleep 20

echo
waydroid status || true
echo
echo "Next: run 'waydroid show-full-ui' inside Hyprland."
echo "If it fails, collect:"
echo "  waydroid log --details-to-stdout | tail -100"
echo "  journalctl -u waydroid-container -n 100 --no-pager"
