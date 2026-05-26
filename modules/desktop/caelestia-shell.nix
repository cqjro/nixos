{ inputs, ... }:
{
	imports = [
		inputs.caelestia-shell.homeManagerModules.default
	];


	xdg.configFile."caelestia/shell.json".text = builtins.toJSON {
		bar = {
			activeWindow = {
				inverted = true;
			};
			status = {
				showBattery = false;
				showSpeaker = true;       # add speaker/volume to taskbar
				showMicrophone = true;    # add microphone to taskbar
				showCapsLock = false;     # remove capslock indicator
			};
			clock = {
				showIcon = false;         # hide the clock icon
				showTime = true;
				showDate = true;
			};
		};
		notifications = {
			nowPlaying = true;            # show now playing in notifications
			showOnFullscreen = true;      # show toasts/notifications over fullscreen
		};
		launcher = {
			showOnHover = true;           # show launcher on hover
			vimKeybinds = true;           # enable vim keybinds in launcher
		};
		background = {
			enabled = false;
		};
		services = {
			smartScheme = false;
		};
	};

	programs.caelestia = {
		enable = true;
		systemd = {
			enable = true;
			target = "graphical-session.target";
			environment = [];
		};
		cli.enable = true;
	};
}
