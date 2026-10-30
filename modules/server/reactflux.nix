{ inputs, ... }:
let
	system = "x86_64-linux";
	# REDRUM is built from the pinned nixpkgs (see modules/hosts/REDRUM/T2-PIN.md),
	# so the build toolchain below must come from the same pins for a stable hash.
	pkgs = inputs.nixpkgs-redrum.legacyPackages.${system};

	# ReactFlux (electh/ReactFlux) is a third-party web frontend for Miniflux.
	# It's not packaged in nixpkgs and the repo ships no flake.nix, so the source
	# is pinned by rev via fetchFromGitHub. It's a pure static SPA: the browser
	# talks directly to the Miniflux API (CORS), so it only needs a static server.
	# The pinned rev below is BOTH the source hash and the miniflux integration
	# points in the README; bump it by:
	#   1. updating `rev` + re-running `nix-prefetch-url --unpack <tarball>`
	#   2. re-fetching the pnpm deps (see `reactflux-pnpm-deps`)
	reactfluxRev = "49414d990108a1d8ce72c9aa2c06dcc7382fa1fb";
	reactfluxSrc = pkgs.fetchFromGitHub {
		owner = "electh";
		repo = "ReactFlux";
		rev = reactfluxRev;
		hash = "sha256-cuPHvF8gLd1P9+bPUlPKtD684QxA4s8Rg/a60h2fG5E=";
	};
	reactfluxVersion = builtins.substring 0 8 reactfluxRev;

	# The project is pnpm-based (packageManager: pnpm@11.21.0) and built with
	# node 22 (engines >= 22.22.0), mirroring the upstream Dockerfile.
	# NOTE: this pin currently equals pkgs.pnpm from the pinned nixpkgs
	# (11.21.0), so pnpm's manage-package-manager-versions never triggers a
	# self-download of a second pnpm. That coincidence is the only reason the
	# derivations below are safe — when they broke on a mismatch, see the
	# abt-sidecar postmortem in modules/server/actual-budget-tweaks.nix
	# ("Failed to switch pnpm to vX … ENOENT"). If the T2 pin is lifted
	# (T2-PIN.md) or either version drifts, strip packageManager from
	# package.json in BOTH derivations below (node one-liner as in
	# actual-budget-tweaks.nix) and re-fetch the FOD outputHash, or the next
	# deps rebuild dies in the sandbox.
	nodejs = pkgs.nodejs_22;
	pnpm = pkgs.pnpm.override { inherit nodejs; };

	# pnpm deps are downloaded once as a fixed-output derivation (FOD) whose
	# output IS the pnpm content-addressed store PLUS the pnpm metadata cache
	# (needed for `--offline` resolution in the build below). Network is allowed
	# inside a FOD build, so this is the single place the npm registry is
	# touched. The build below then installs --offline against both, exactly like
	# the Docker image only fetches deps once at build time.
	#
	# FIXME: `outputHash` is NOT reproducible across machines/dates. The build
	# is shared between GOD-KILLER and REDRUM (different pin/nixpkgs), and pnpm
	# re-resolves floating dep ranges from the live registry on every fetch, so
	# the store+cache output drifts and the hash mismatches (observed
	# 2026-10-20: Nr0e0+PW… -> 3loMT2kp…). Same failure mode as the ABT FOD in
	# modules/server/actual-budget-tweaks.nix — both broke in one session.
	# TODO: make this stable — ideally replace this hand-rolled FOD with a
	# lockfile-frozen fetch (e.g. `fetchPnpmDeps` / `pnpm.fetchDeps`) once the
	# pinned nixpkgs ships one that works with this project's lockfile, so the
	# hash stops drifting and cross-host builds stop failing.
	pnpmDeps = pkgs.stdenv.mkDerivation {
		pname = "reactflux-pnpm-deps";
		version = reactfluxVersion;
		src = reactfluxSrc;
		nativeBuildInputs = [ nodejs pnpm pkgs.cacert ];
		# node doesn't inherit the nix CA bundle; without this pnpm can't verify
		# registry.npmjs.org inside the sandbox (UNABLE_TO_GET_ISSUER_CERT_LOCALLY).
		SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
		NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
		outputHashMode = "recursive";
		outputHashAlgo = "sha256";
		outputHash = "sha256-3loMT2kpj/gZi/GipJXxQy19v+RV+qGifOZ6SfezcKI=";
		phases = [ "installPhase" ];
		installPhase = ''
			runHook preInstall
			export HOME="$TMPDIR"
			mkdir -p "$HOME/.cache/pnpm" "$out"
			cp -r "$src" ./reactflux
			chmod -R u+w ./reactflux
			# Mirror upstream Docker: install without pnpm-workspace.yaml so
			# `minimumReleaseAge`/`allowBuilds` never trigger registry checks.
			rm -f ./reactflux/pnpm-workspace.yaml
			cd ./reactflux
			# Safe while pkgs.pnpm (11.21.0) == packageManager pin; on any
			# drift strip packageManager first (see note at `pnpm` above).
			pnpm config set store-dir "$out/store"
			pnpm config set cache-dir "$out/cache"
			pnpm install --frozen-lockfile --ignore-scripts
			runHook postInstall
		'';
	};

	reactflux = pkgs.stdenv.mkDerivation {
		pname = "reactflux";
		version = reactfluxVersion;
		src = reactfluxSrc;
		nativeBuildInputs = [ nodejs pnpm pkgs.cacert ];
		SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
		NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
		# Single phase (like the FOD above): pnpm needs a stable writable cwd,
		# and mixing buildPhase/installPhase caused stdenv to reset the working
		# dir between them, losing the build output location.
		phases = [ "installPhase" ];
		installPhase = ''
			runHook preInstall
			export HOME="$TMPDIR"
			mkdir -p "$HOME/.cache/pnpm"
			cp -r "$src" ./reactflux
			chmod -R u+w ./reactflux
			rm -f ./reactflux/pnpm-workspace.yaml
			cd ./reactflux
			# pnpm needs a *writable* store+metadata cache (it keeps a sqlite
			# index inside the store), so copy the immutable FOD output into the
			# build dir and re-point both store-dir and cache-dir at the copies.
			cp -r "${pnpmDeps}" "$TMPDIR/pnpm"
			chmod -R u+w "$TMPDIR/pnpm"
			pnpm config set store-dir "$TMPDIR/pnpm/store"
			pnpm config set cache-dir "$TMPDIR/pnpm/cache"
			pnpm install --frozen-lockfile --offline --ignore-scripts
			# prebuild (version-info.js) + vite build; VITE_BASE_PATH defaults to "/"
			pnpm run build
			mkdir -p "$out"
			cp -r ./build/. "$out"/
			runHook postInstall
		'';
	};
in
{
	flake.packages.${system} = {
		reactflux = reactflux;
		reactflux-pnpm-deps = pnpmDeps;
	};

	flake.modules.nixos.reactflux = { lib, ... }: {
		# ReactFlux is static files, so there's no app user or data dir of its
		# own — nginx (its own hardened system user) serves the immutable store
		# path from the derivation above. Only reachable via cloudflared tunnel.
		services.nginx = {
			enable = true;
			# Bound to localhost only; cloudflared forwards public traffic.
			defaultListen = [{ addr = "127.0.0.1"; port = 8085; }];
			virtualHosts."flux.cqjro.ca" = {
				listen = [{ addr = "127.0.0.1"; port = 8085; }];
				root = reactflux;
				# SPA: route unknown paths (client-side routes) to index.html.
				locations."/".tryFiles = "$uri $uri/ /index.html";
			};
		};

		services.cloudflared = {
			tunnels."43d74f1c-1cc5-4083-a331-5ca34191dd37" = {
				# TODO: replace with your tunnel UUID (cloudflared tunnel create reactflux)
				credentialsFile = "/var/lib/cloudflared/reactflux.json";
				default = "http_status:404";
				ingress = {
					"flux.cqjro.ca" = "http://localhost:8085";
				};
			};
		};
	};
}
