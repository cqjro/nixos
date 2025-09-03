{config, lib, pkgs, ...}:
{
	options = {
		games.enable = lib.mkEnableOption "enable games";
	};
	config = lib.mkIf config.games.enable {
		environment.systemPackages = with pkgs; [
			mangohud # minial performance hud
			lutris # linxu game launcher
			heroic # epic games launcher for linux
			itch # indie games
			protonup # proton management
			bottles # manager for wine programs (games or otherwise)
			wineWowPackages.stable # wine
			# minecraft # this is not working on nixos currently
			prismlauncher # open source minecraft launcher
		];

		# specifies proton install location
		environment.sessionVariables = {
			STEAM_EXTRA_COMPAT_TOOLS_PATH = "\${HOME}/.steam/root/compatibilitytools.d";
		};

		programs.steam = {
			enable = true;
			# gamescopeSession.enable = true; # starts game in a microcompositor if there is resolution/upscaling issues on DE/window manager
		};

		programs.appimage.enable = true;
		programs.gamemode.enable = true;
	};
}
