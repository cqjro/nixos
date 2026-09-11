{ ... }:
{
	flake.modules.nixos.games = { pkgs, lib, inputs, config, ... }: {
		# NOTE: switching manifest.enableMillennium to false needs the leftover
		# bootstrap symlinks removed first:
		# `rm ~/.local/share/Steam/ubuntu12_{32,64}/libXtst.so.6`
		nixpkgs.overlays = lib.mkIf config.manifest.enableMillennium [
			inputs.nixos-millennium.overlays.default
		];

		nix.settings = lib.mkIf config.manifest.enableMillennium {
			trusted-public-keys = [
				"nixos-millennium.cachix.org-1:AaMK3uqfgzCUpjs7+gdHTwwaqkT/vvLMCnUKSY37QAQ="
			];
			substituters = [
				"https://nixos-millennium.cachix.org"
			];
		};

		environment.systemPackages = with pkgs; [
			mangohud # minial performance hud
			# lutris # linxu game launcher
			heroic # epic games launcher for linux
			itch # indie games
			protonup-ng # proton management
			# bottles # manager for wine programs (games or otherwise)
			# wineWowPackages.stable # wine
			# minecraft # this is not working on nixos currently
			prismlauncher # open source minecraft launcher
			gamescope-wsi # HDR support with gamescope
		];

		# specifies proton install location
		environment.sessionVariables = {
			STEAM_EXTRA_COMPAT_TOOLS_PATH = "\${HOME}/.steam/root/compatibilitytools.d";
		};

		programs.steam = {
			enable = true;
			extest.enable = true;

			package = if config.manifest.enableMillennium
				then pkgs.millennium-steam # steam with millennium theming
				else pkgs.steam; # vanilla client as a fallback

			remotePlay.openFirewall = true;
			dedicatedServer.openFirewall = true;

			gamescopeSession = {
				enable = true; # starts game in a microcompositor if there is resolution/upscaling issues on DE/window manager
				env = {
					__GL_VRR_ALLOWED = "0";
				};
				args = [
					"-w" "3840"
					"-h" "2160"
					"-r" "165"
				];
			};

			extraPackages = with pkgs; [
				hidapi # fixes steam controller firmware update issues
			];
			extraCompatPackages = with pkgs; [
				proton-ge-bin # adding proton GE
			];
		};

		programs.gamescope = {
			enable = true;
			enableWsi = true;
			capSysNice = false;
		};

		programs.appimage.enable = true;
		programs.gamemode.enable = true;
	};
}