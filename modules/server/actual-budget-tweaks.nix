{ inputs, ... }:
let
	system = "x86_64-linux";
	# REDRUM is built from the pinned nixpkgs (see modules/hosts/REDRUM/T2-PIN.md),
	# so the build toolchain below must come from the same pins for a stable hash.
	pkgs = inputs.nixpkgs-redrum.legacyPackages.${system};

	# Actual Budget Tweaks (aelxxs/actual-budget-tweaks) layers optional UI
	# tweaks onto Actual Budget's web interface: themes, live sidebar, budget
	# insights, spending calendar, and a mobile section that restyles the web
	# app with a tab bar, bottom sheets and snackbars. It ships as a browser
	# extension, and also as the "sidecar" used here: a dependency-free Node
	# reverse proxy (docker/server.js) that injects the built extension bundle
	# into every page Actual serves, so every browser and phone that opens the
	# address gets the tweaks with no extension installed. It stores nothing;
	# budget data stays in Actual. Pinned by release-tag commit; bump by:
	#   1. updating `rev` + re-running `nix-prefetch-url --unpack <tarball>`
	#      and setting `abtVersion` to the new tag
	#   2. re-fetching the pnpm deps (see `abtSidecarPnpmDeps`: build with a
	#      wrong hash once, copy the "got" hash Nix prints)
	abtRev = "c429ead9006538e4281a825c37f20bf1f0955afc"; # v0.1.100
	abtVersion = "0.1.100";
	abtSrc = pkgs.fetchFromGitHub {
		owner = "aelxxs";
		repo = "actual-budget-tweaks";
		rev = abtRev;
		hash = "sha256-Mpca8yVkzVSXvsdVxeEK+YL3wXnhlZPZIsqNnCDrKG0=";
	};

	# The project is pnpm-based (packageManager: pnpm@10.19.0, lockfile
	# v9.0) and needs node >= 22.13 (engines), mirroring upstream's
	# Dockerfile (node:22-alpine + corepack pnpm).
	nodejs = pkgs.nodejs_22;
		pnpm = pkgs.pnpm_10.override { inherit nodejs; };

	# pnpm deps are downloaded once as a fixed-output derivation (FOD) whose
	# output IS the pnpm content-addressed store PLUS the pnpm metadata cache
	# (needed for `--offline` resolution in the build below). Network is allowed
	# inside a FOD build, so this is the single place the npm registry is
	# touched — same pattern as modules/server/reactflux.nix.
	pnpmDeps = pkgs.stdenv.mkDerivation {
		pname = "abt-sidecar-pnpm-deps";
		version = abtVersion;
		src = abtSrc;
		nativeBuildInputs = [ nodejs pnpm pkgs.cacert ];
		# node doesn't inherit the nix CA bundle; without this pnpm can't verify
		# registry.npmjs.org inside the sandbox (UNABLE_TO_GET_ISSUER_CERT_LOCALLY).
		SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
		NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
		outputHashMode = "recursive";
		outputHashAlgo = "sha256";
		outputHash = "sha256-LTBNkyKFV+Gb8vha+lVdCAMaV66+L3SyOubUtcIYN70=";
		phases = [ "installPhase" ];
		installPhase = ''
			runHook preInstall
			export HOME="$TMPDIR"
			mkdir -p "$HOME/.cache/pnpm" "$out"
			cp -r "$src" ./abt
			chmod -R u+w ./abt
			cd ./abt
			pnpm config set store-dir "$out/store"
			pnpm config set cache-dir "$out/cache"
			# --ignore-scripts skips `wxt prepare` (postinstall); the real build
			# below regenerates what it needs locally.
			pnpm install --frozen-lockfile --ignore-scripts
			runHook postInstall
		'';
	};

	# Build the extension bundle (wxt build -> .output/chrome-mv3, the same
	# output the upstream Docker image ships) and package it next to the
	# sidecar server + browser shim, so the runtime is one immutable store path.
	abtSidecar = pkgs.stdenv.mkDerivation {
		pname = "abt-sidecar";
		version = abtVersion;
		src = abtSrc;
		nativeBuildInputs = [ nodejs pnpm pkgs.cacert ];
		SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
		NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
		COREPACK_ENABLE_STRICT = "0";
		COREPACK_ENABLE_DOWNLOAD_PROMPT = "0";
		# Single phase (like the FOD above): pnpm needs a stable writable cwd,
		# and mixing buildPhase/installPhase caused stdenv to reset the working
		# dir between them, losing the build output location.
		phases = [ "installPhase" ];
		installPhase = ''
			runHook preInstall
			export HOME="$TMPDIR"
			export COREPACK_ENABLE_STRICT=0
			export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
			export CI=1
			corepack disable || true
			mkdir -p "$HOME/.cache/pnpm" "$PNPM_HOME/bin" 2>/dev/null || true
			cp "${pnpm}/bin/pnpm" "$PNPM_HOME/bin/pnpm" 2>/dev/null || ln -s "$(command -v pnpm)" "$PNPM_HOME/bin/pnpm" 2>/dev/null || true
			export PATH="${pnpm}/bin:$PATH"
			mkdir -p "$HOME/.cache/pnpm"
			cp -r "$src" ./abt
			chmod -R u+w ./abt
			cd ./abt
			# Remove packageManager pin so corepack/pnpm won't try to fetch
			# a different pnpm version from the registry.
			node -e "const p=require('./package.json');delete p.packageManager;require('fs').writeFileSync('./package.json',JSON.stringify(p,null,'\t')+'\n');"
			# pnpm needs a *writable* store+metadata cache (it keeps a sqlite
			# index inside the store), so copy the immutable FOD output into the
			# build dir and re-point both store-dir and cache-dir at the copies.
			rm -rf "$TMPDIR/pnpm"
			cp -r "${pnpmDeps}" "$TMPDIR/pnpm"
			chmod -R u+w "$TMPDIR/pnpm"
			pnpm config set store-dir "$TMPDIR/pnpm/store"
			pnpm config set cache-dir "$TMPDIR/pnpm/cache"
			pnpm config set verify-store-integrity false
			pnpm install --frozen-lockfile --offline --ignore-scripts --prefer-offline 2>&1 | tail -20
			# wxt build: compiles the Svelte/TS bundle as a Chrome MV3 extension
			# (prepare runs locally inside wxt, no network needed).
			pnpm run build
			mkdir -p "$out"
			cp -r .output/chrome-mv3 "$out/assets"
			cp docker/server.js docker/browser-shim.js "$out/"
			cp package.json "$out/"
			runHook postInstall
		'';
	};
in
{
	flake.packages.${system} = {
		abt-sidecar = abtSidecar;
		abt-sidecar-pnpm-deps = pnpmDeps;
	};

	flake.modules.nixos.actual-budget-tweaks = { config, lib, ... }: {
		options.services.abt-sidecar.enable = lib.mkEnableOption ''
			the Actual Budget Tweaks sidecar, a small reverse proxy in front of
			Actual that injects UI tweaks (themes, sidebar, mobile restyle)
			into every browser that opens budget.cqjro.ca. While disabled the
			tunnel keeps pointing at Actual directly, and every trace of the
			sidecar (service, user, ingress override) is removed by NixOS
		'';

		config = lib.mkIf config.services.abt-sidecar.enable {
			users.users.abt = {
				isSystemUser = true;
				group = "abt";
				home = "/var/lib/abt";
				createHome = true;
			};
			users.groups.abt = {};

			systemd.services.abt-sidecar = {
				description = "Actual Budget Tweaks sidecar proxy";
				# The sidecar needs Actual answering on 127.0.0.1:5006, but a
				# down Actual should not stop the proxy (it returns 502).
				after = [ "actual.service" ];
				wants = [ "actual.service" ];
				wantedBy = [ "multi-user.target" ];
				serviceConfig = {
					User = "abt";
					Group = "abt";
					ExecStart = "${nodejs}/bin/node ${abtSidecar}/server.js";
					Environment = [
						"PORT=8086"
						"ACTUAL_ORIGIN=http://127.0.0.1:5006"
						"ASSETS_DIR=${abtSidecar}/assets"
						"PACKAGE_JSON_PATH=${abtSidecar}/package.json"
						"HOME=/var/lib/abt"
					];
					# The sidecar stores nothing and runs from a read-only store
					# path, so the unit stays fully static across rebuilds.
					Restart = "on-failure";
					RestartSec = 5;
					NoNewPrivileges = true;
					PrivateTmp = true;
					ProtectSystem = "strict";
					ProtectHome = true;
					ProtectKernelTunables = true;
					ProtectKernelModules = true;
					ProtectControlGroups = true;
					RestrictSUIDSGID = true;
				};
			};

			# Flip budget.cqjro.ca from Actual to the sidecar while enabled.
			# mkForce overrides the base ingress in
			# modules/server/actual-budget.nix; setting
			# services.abt-sidecar.enable = false reverts the tunnel to
			# http://localhost:5006 automatically on the next rebuild.
			services.cloudflared.tunnels."ad444bc6-e186-49a2-ac8d-7a9f1bba6617" = {
				ingress."budget.cqjro.ca" = lib.mkForce "http://127.0.0.1:8086";
			};
		};
	};
}
