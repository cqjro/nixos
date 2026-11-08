{ ... }:
{
	# TODO-remove: DWSIM is not in nixpkgs, so this module repackages the
	# upstream .deb by hand. When `pkgs.dwsim` lands, rewrite the module around it
	# and drop the .deb derivation, the version/hash options and dwsim-update.sh.
	# Tracked in the "Pending upstream fixes" registry
	# (docs/agents/upstream-registry.md row 14 / README).
	#
	# DWSIM: open-source chemical process simulator (GPL-3). It is not in
	# nixpkgs, and upstream ships Linux only as a .deb / tarball with its own
	# .NET runtime bundled (a self-contained net10.0 app, no wine, no Mono).
	# This repackages the official amd64 .deb from the DanWBR/dwsim10 releases:
	# unpack to $out/opt/dwsim, patch the native libs, and wrap the launcher.
	#
	# Version: the defaults below are the latest release when this was written.
	# To move to a newer release run `modules/scripts/dwsim-update.sh`, which
	# prints the new `version` and `hash`. To pin an older one, set both options
	# per host (hosts/<HOST>/home.nix):
	#   dwsim.version = "10.2.14";
	#   dwsim.hash = "sha256-...";   # from the release's asset digest
	flake.modules.homeManager."dwsim" = { config, lib, pkgs, ... }:
		let
			cfg = config.dwsim;
			dwsim = pkgs.stdenv.mkDerivation {
				pname = "dwsim";
				inherit (cfg) version;

				src = pkgs.fetchurl {
					url = "https://github.com/DanWBR/dwsim10/releases/download/v${cfg.version}/dwsim_${cfg.version}_amd64.deb";
					inherit (cfg) hash;
				};

				nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook makeWrapper ];

				# direct (DT_NEEDED) dependencies of the bundled native libs
				buildInputs = with pkgs; [
					stdenv.cc.cc.lib # libstdc++, libgcc_s
					fontconfig # libSkiaSharp
					lttng-ust # libcoreclrtraceptprovider (tracing only)
				];
				# the tracing provider is optional; do not fail if its soname differs
				autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];

				unpackPhase = "dpkg-deb -x $src .";
				dontConfigure = true;
				dontBuild = true;
				# the bundled .NET runtime is sensitive to stripping
				dontStrip = true;

				installPhase = ''
					runHook preInstall
					mkdir -p $out
					cp -r opt $out/opt
					cp -r usr/share $out/share
					# .NET opens libs by name at run time (not in DT_NEEDED), so the
					# wrapper puts them on the loader path
					makeWrapper $out/opt/dwsim/DWSIM.UI.Desktop.Avalonia $out/bin/dwsim \
						--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath (with pkgs; [
							icu
							openssl
							zlib
							fontconfig
							freetype
							libGL
							libx11
							libice
							libsm
							libxcursor
							libxext
							libxi
							libxrandr
							libxkbcommon
						])} \
						--set DOTNET_gcServer 0
					substituteInPlace $out/share/applications/dwsim.desktop \
						--replace-fail "Exec=dwsim" "Exec=$out/bin/dwsim"
					runHook postInstall
				'';

				meta = {
					description = "Open-source chemical process simulator";
					homepage = "https://dwsim.org";
					license = lib.licenses.gpl3Plus;
					sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
					mainProgram = "dwsim";
					platforms = [ "x86_64-linux" ];
				};
			};
		in {
			options.dwsim = {
				version = lib.mkOption {
					type = lib.types.str;
					default = "10.2.15";
					description = "DWSIM release to install (a tag of github.com/DanWBR/dwsim10, without the leading v).";
				};
				hash = lib.mkOption {
					type = lib.types.str;
					default = "sha256-CVoTPo1zUTWiERnp41tLVndHuezUjrOQjVBzyYyROZk=";
					description = "SRI hash of dwsim_<version>_amd64.deb; must be changed together with `dwsim.version`.";
				};
			};

			config.home.packages = [ dwsim ];
		};
}
