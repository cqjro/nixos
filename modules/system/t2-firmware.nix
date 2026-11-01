{ inputs, ... }:
let
	system = "x86_64-linux";
	pkgs = inputs.nixpkgs.legacyPackages.${system};
in
{
	# `nix run .#t2-firmware-import -- HOST [DIR]` — see modules/scripts/t2-firmware-import.sh
	flake.packages.${system}.t2-firmware-import = pkgs.writeShellApplication {
		name = "t2-firmware-import";
		runtimeInputs = [ pkgs.nix pkgs.coreutils pkgs.findutils ];
		text = builtins.readFile ../scripts/t2-firmware-import.sh;
	};

	# Apple Broadcom Wi-Fi/Bluetooth firmware for T2 Macs (REDRUM, LittleNix).
	# The files are extracted from macOS and are not redistributable, so they are
	# NOT in git: the store path is pinned by hash and must already exist in the
	# local store (`requireFile`). Evaluation never needs the files, only the build
	# does, so `nix flake check` / `nix eval` work from a clean clone or a worktree.
	# Full story and how to place the files: docs/firmware.md.
	flake.modules.nixos."t2-firmware" = { config, lib, pkgs, ... }:
	let
		cfg = config.t2-firmware;
		host = config.networking.hostName;

		src =
			if cfg.hash == null then
				pkgs.runCommand "brcm-firmware-unpinned" { allowSubstitutes = false; } ''
					echo "t2-firmware.hash is not set for ${host}." >&2
					echo "Extract the firmware, run: nix run .#t2-firmware-import -- ${host} <dir>" >&2
					echo "then set t2-firmware.hash to the NAR hash it prints (docs/firmware.md)." >&2
					exit 1
				''
			else
				pkgs.requireFile {
					name = "brcm-firmware";
					hash = cfg.hash;
					hashMode = "recursive";
					message = ''
						The Apple Broadcom firmware for ${host} is not in the Nix store.
						It is proprietary, extracted from macOS, and deliberately not in git.

						1. Put the extracted brcm files in ${cfg.stagingDir}
						   (copy them from the machine that has them, or extract them with
						   the t2linux firmware script; see docs/firmware.md).
						2. From the repo checkout run:
						     nix run .#t2-firmware-import -- ${host}
						   or by hand:
						     nix store add --name brcm-firmware ${cfg.stagingDir}
						Expected NAR hash: ${cfg.hash}
					'';
				};
	in
	{
		options.t2-firmware = {
			hash = lib.mkOption {
				type = lib.types.nullOr lib.types.str;
				default = null;
				example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
				description = ''
					SRI NAR hash of this host's extracted `brcm` firmware directory
					(`nix hash path --type sha256 --sri <dir>`). The hash is not a
					secret; the files are. While null the firmware derivation fails to
					build with instructions (evaluation still works).
				'';
			};
			stagingDir = lib.mkOption {
				type = lib.types.str;
				default = "/var/lib/firmware-src/${host}/brcm";
				description = ''
					Out-of-repo directory where the extracted files are kept on this
					machine. Only used for the instructions and the importer's default;
					builds read the Nix store, not this directory.
				'';
			};
		};

		config = {
			hardware.firmware = [
				(pkgs.runCommand "brcm-firmware" { allowSubstitutes = false; preferLocalBuild = true; } ''
					mkdir -p $out/lib/firmware/brcm
					cp ${src}/* "$out/lib/firmware/brcm"
				'')
			];

			# World-readable on purpose (not a secret; no home-dir 0700 problem for
			# the t3code user), writable by the human who places the files.
			systemd.tmpfiles.rules = [
				"d /var/lib/firmware-src 0755 cairo users -"
				"d /var/lib/firmware-src/${host} 0755 cairo users -"
			];
		};
	};
}
