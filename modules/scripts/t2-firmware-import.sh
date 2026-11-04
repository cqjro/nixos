#!/usr/bin/env bash

# Imports a host's Apple Broadcom Wi-Fi/Bluetooth firmware (extracted from
# macOS, NOT in git — see docs/firmware.md) into the Nix store and pins it with
# a GC root, so `nixos-rebuild build|switch` of that T2 host can find it on this
# machine. Run it on every machine that builds the host (GOD-KILLER and/or the
# host itself). Exposed as `nix run .#t2-firmware-import -- HOST [DIR]`.
#
# The store path is content-addressed, so it is byte-for-byte the path the
# `requireFile` in modules/system/t2-firmware.nix expects whenever the files match
# the hash pinned in the host's machine.nix. Nothing here is a secret or leaves
# this machine.

usage() {
	echo "usage: t2-firmware-import HOST [DIR]" >&2
	echo "  HOST  T2 host name (REDRUM, LittleNix)" >&2
	echo "  DIR   directory holding the extracted brcm files" >&2
	echo "        (default: /var/lib/firmware-src/HOST/brcm)" >&2
	echo "env: T2_FIRMWARE_FLAKE  flake to read the pinned hash from (default: .)" >&2
	exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
host=$1
src=${2:-/var/lib/firmware-src/$host/brcm}
flake=${T2_FIRMWARE_FLAKE:-.}

export NIX_CONFIG="${NIX_CONFIG:-}"$'\n'"experimental-features = nix-command flakes"

if [[ ! -d $src ]]; then
	echo "error: $src is not a directory." >&2
	echo "Put the extracted brcm firmware files there first (see docs/firmware.md," >&2
	echo "section \"Placing the files\")." >&2
	exit 1
fi

# Names only — never print file contents.
count=$(find "$src" -maxdepth 1 -type f | wc -l)
if [[ $count -eq 0 ]]; then
	echo "error: $src contains no files." >&2
	exit 1
fi

hash=$(nix hash path --type sha256 --sri "$src")
# --name must stay "brcm-firmware": it is part of the store path requireFile expects.
path=$(nix store add --mode nar --hash-algo sha256 --name brcm-firmware "$src")

# Without a root the path is garbage-collected as soon as no system references it
# (e.g. on GOD-KILLER, whose own closure never includes REDRUM's firmware).
root="$(dirname "$src")/brcm-firmware.gcroot"
nix-store --add-root "$root" --indirect --realise "$path" > /dev/null

echo "imported $count files from $src"
echo "  store path : $path"
echo "  NAR hash   : $hash"
echo "  gc root    : $root"

pinned=$(nix eval --raw "$flake#nixosConfigurations.$host.config.t2-firmware.hash" 2> /dev/null || true)
if [[ -z $pinned ]]; then
	echo "note: could not read the pinned hash for $host from $flake (not a checkout, or none set)." >&2
	echo "  Set t2-firmware.hash = \"$hash\"; in modules/hosts/$host/machine.nix if this is the first import." >&2
elif [[ $pinned == "$hash" ]]; then
	echo "OK: matches the hash pinned for $host — the build can now find it."
else
	echo "MISMATCH: machine.nix pins $pinned" >&2
	echo "  These files hash to $hash." >&2
	echo "  If this is the right (new) firmware set, update t2-firmware.hash in modules/hosts/$host/machine.nix." >&2
	echo "  If not, re-copy the correct files and run this again." >&2
	exit 1
fi
