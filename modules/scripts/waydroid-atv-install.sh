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
#   * `waydroid init -f` regenerates waydroid_base.prop, so the AMD GPU and
#     ATV bt_remote_pairing properties have to be re-applied *after* init.
#   * `sudo echo ... >> file` fails (the redirection is unprivileged);
#     `tee -a` is required (this script runs as root, so plain `>>` is fine).
#   * Android userdata is NOT /var/lib/waydroid/userdata.img on this setup.
#     Waydroid stores it under waydroid.host_data_path, by default
#     ~/.local/share/waydroid/data. Leftover data from an older Android
#     release makes zygote/system_server crash-loop, so it must be removed
#     for a real factory reset (`init -f` does not touch it).

set -euo pipefail

system_zip="/nix/store/0mir7hkikihy37ffg63rlyc3h1qnc7vx-lineage-24.0-20261017-GAPPS-waydroid_x86_64-system.zip"
vendor_zip="/nix/store/0qx3pqpfbxaszss4ly0c8zgv87mzpbr9-lineage-24.0-20261017-MAINLINE-waydroid_x86_64-vendor.zip"

while [ $# -gt 0 ]; do
	case "$1" in
		--system) system_zip="$2"; shift 2 ;;
		--vendor) vendor_zip="$2"; shift 2 ;;
		-h|--help) sed -n '2,25p' "$0"; exit 0 ;;
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

# Android userdata lives in ~/.local/share/waydroid (waydroid.host_data_path).
# Remember the session user before the old props are regenerated.
data_user="${SUDO_USER:-}"
if [ -z "$data_user" ]; then
	data_user="$(sed -n 's/^waydroid.host.user=//p' /var/lib/waydroid/waydroid.prop 2>/dev/null | head -n1)" || true
fi
data_home=""
if [ -n "$data_user" ]; then
	data_home="$(getent passwd "$data_user" | cut -d: -f6)" || data_home=""
fi

# Remove the *directory*, not just its contents -- see header comment.
echo "==> clearing previous images and userdata"
rm -rf /etc/waydroid-extra
rm -rf /var/lib/waydroid/overlay /var/lib/waydroid/overlay_rw /var/lib/waydroid/overlay_work
rm -f /var/lib/waydroid/userdata.img
if [ -n "$data_home" ] && [ -d "$data_home" ]; then
	echo "==> wiping Android userdata: $data_home/.local/share/waydroid"
	rm -rf "$data_home/.local/share/waydroid"
else
	echo "WARNING: could not determine the Waydroid session user;" >&2
	echo "         remove ~/.local/share/waydroid manually before starting." >&2
fi

echo "==> extracting images"
mkdir -p /etc/waydroid-extra/images
unzip -o "$system_zip" -d /etc/waydroid-extra/images
unzip -o "$vendor_zip" -d /etc/waydroid-extra/images
ls -lh /etc/waydroid-extra/images

echo "==> waydroid init -f"
waydroid init -f

echo "==> applying GOD-KILLER GPU props to waydroid_base.prop"
# Waydroid renders on the AMD iGPU; its probe skips NVIDIA. Pick the first
# non-NVIDIA render node so this still works if the iGPU enumeration moves.
render_node=""
for sys_node in /sys/class/drm/renderD*; do
	driver="$(basename "$(readlink -f "$sys_node/device/driver")" 2>/dev/null || true)"
	case "$driver" in
		nvidia|nvidia-*) continue ;;
	esac
	render_node="/dev/dri/$(basename "$sys_node")"
	break
done
[ -n "$render_node" ] || render_node=/dev/dri/renderD129

set_prop() {
	sed -i "/^$1=/d" /var/lib/waydroid/waydroid_base.prop
	echo "$1=$2" >> /var/lib/waydroid/waydroid_base.prop
}

set_prop gralloc.gbm.device "$render_node"
set_prop ro.hardware.egl mesa
set_prop ro.hardware.vulkan radeon
set_prop ro.hardware.gralloc minigbm_gbm_mesa
# The container has no Bluetooth; remotes are paired host-side (PLAN.md).
set_prop atv.setup.bt_remote_pairing false

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
