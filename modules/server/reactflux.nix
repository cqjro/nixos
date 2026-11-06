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
	# node 22 (engines >= 22.22.0), mirroring the upstream Dockerfile. The
	# nixpkgs pnpm helpers below set `pnpm_config_pm_on_fail=ignore`, so a
	# packageManager pin that differs from pkgs.pnpm no longer makes pnpm try to
	# download a second pnpm inside the sandbox (the abt-sidecar failure, see
	# modules/server/actual-budget-tweaks.nix).
	nodejs = pkgs.nodejs_22;
	pnpm = pkgs.pnpm.override { nodejs-slim = pkgs.nodejs-slim_22; };

	# pnpm deps are downloaded once as a fixed-output derivation (FOD). This uses
	# nixpkgs' own fetcher (fetcherVersion 4 = pnpm 11) instead of the hand-rolled
	# FOD this file had: that one hashed differently on every fetch (REDRUM and
	# GOD-KILLER disagreed, 2026-11-06) because pnpm 11 keeps per-file `checkedAt`
	# timestamps in a SQLite index (`store/v11/index.db`) plus a registry metadata
	# cache. The fetcher strips the timestamps, dumps the index to SQL text and
	# packs a reproducible tarball; `pnpmConfigHook` below rebuilds the database
	# and installs offline. A new hash is needed only when the source rev, the
	# lockfile or the pnpm version change.
	pnpmDeps = pkgs.fetchPnpmDeps {
		pname = "reactflux";
		version = reactfluxVersion;
		src = reactfluxSrc;
		inherit pnpm;
		fetcherVersion = 4;
		# Mirror upstream Docker: install without pnpm-workspace.yaml so
		# `minimumReleaseAge`/`allowBuilds` never trigger registry checks.
		postPatch = ''
			rm -f pnpm-workspace.yaml
		'';
		hash = "sha256-4dG37WfdVPFy/DESAlQA8uvtO5j+o22KgUpQBzKECYk=";
	};

	reactflux = pkgs.stdenv.mkDerivation {
		pname = "reactflux";
		version = reactfluxVersion;
		src = reactfluxSrc;
		inherit pnpmDeps;
		nativeBuildInputs = [ nodejs pnpm pkgs.pnpmConfigHook ];
		postPatch = ''
			rm -f pnpm-workspace.yaml
		'';
		buildPhase = ''
			runHook preBuild
			# prebuild (version-info.js) + vite build; VITE_BASE_PATH defaults to "/"
			pnpm run build
			runHook postBuild
		'';
		installPhase = ''
			runHook preInstall
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
