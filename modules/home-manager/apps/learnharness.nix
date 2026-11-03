{ ... }:
{
	# LearnHarness: an AGPL-3.0 Electron desktop app where AI agents probe, plan,
	# teach and drill you on a persistent knowledge graph. The provider API key is
	# entered inside the app and stored in the system keyring (the shared `keyring`
	# fragment), so nothing secret lives in this repo.
	flake.modules.homeManager."learnharness" = { pkgs, ... }:
		let
			# TODO-remove: LearnHarness is not in nixpkgs and upstream ships no
			# flake/Nix expression, so the app is pinned as an AppImage. Switch to
			# `pkgs.learnharness` (or a flake input) when either is available. Its
			# "Pending upstream fixes" registry row is still to be added (it waits
			# on the docs refactor that moves the registry to
			# docs/agents/upstream-registry.md; see TODO.md).
			version = "0.4.1";
			src = pkgs.fetchurl {
				url = "https://github.com/amosblomqvist/learnharness/releases/download/v${version}/LearnHarness-${version}-x86_64.AppImage";
				hash = "sha256-n8aA23BE2DD7yePDAbuWcLc29jo22bYivln2toh3DNg=";
			};
			appimageContents = pkgs.appimageTools.extract {
				pname = "learnharness";
				inherit version src;
			};
			learnharness = pkgs.appimageTools.wrapType2 {
				pname = "learnharness";
				inherit version src;

				nativeBuildInputs = [ pkgs.makeWrapper ];

				# The AppImage cannot self-update from the read-only store path, so
				# bump `version` and `hash` here instead.
				extraInstallCommands = ''
					install -m 444 -D ${appimageContents}/learnharness.desktop \
						$out/share/applications/learnharness.desktop
					install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/learnharness.png \
						$out/share/icons/hicolor/512x512/apps/learnharness.png
					substituteInPlace $out/share/applications/learnharness.desktop \
						--replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=learnharness %U'
					wrapProgram $out/bin/learnharness \
						--add-flags --no-sandbox
				'';

				meta = {
					description = "AI agent harness for learning: adaptive teaching, practice and a persistent knowledge graph";
					homepage = "https://github.com/amosblomqvist/learnharness";
					license = pkgs.lib.licenses.agpl3Only;
					platforms = [ "x86_64-linux" ];
					mainProgram = "learnharness";
				};
			};
		in {
			home.packages = [ learnharness ];
		};
}
