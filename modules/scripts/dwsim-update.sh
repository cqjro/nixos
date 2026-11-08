#!/usr/bin/env bash
# Print the latest DWSIM release for modules/home-manager/apps/dwsim.nix:
# the `version` and `hash` to put into the module defaults (or into
# dwsim.version / dwsim.hash for a pinned host). Read-only: edits nothing.
# Usage: dwsim-update.sh [VERSION]   (default: the latest release)
# Needs curl, jq and nix on PATH (all present on GOD-KILLER).
set -euo pipefail

repo=DanWBR/dwsim10
if [ $# -ge 1 ]; then
	json=$(curl -fsS "https://api.github.com/repos/$repo/releases/tags/v${1#v}")
else
	json=$(curl -fsS "https://api.github.com/repos/$repo/releases/latest")
fi

tag=$(jq -r .tag_name <<<"$json")
version=${tag#v}
digest=$(jq -r --arg n "dwsim_${version}_amd64.deb" '.assets[] | select(.name == $n) | .digest' <<<"$json")
[ -n "$digest" ] && [ "$digest" != null ] || { echo "no dwsim_${version}_amd64.deb asset (or digest) in $tag" >&2; exit 1; }

echo "version = \"$version\";"
echo "hash = \"$(nix hash convert --hash-algo sha256 --to sri "${digest#sha256:}")\";"
