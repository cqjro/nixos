{ pkgs, ... }:
{
	home.packages = with pkgs; [ 
		swaynotificationcenter
		libnotify
	];

	services.swaync = {
		enable = true;
		settings = {
			positionX = "right";
			positionY = "top";
			notification-margin-top = 55;
			notification-margin-left = 20;
			layer = "overlay";
			control-center-layer = "overlay";
			layer-shell = true;
			cssPriority = "application";
			control-center-margin-top = 15;
			control-center-margin-bottom = 0;
			control-center-margin-right = 15;
			control-center-margin-left = 0;
			fit-to-screen = false;
			notification-window-width = 500;
			timeout = 3;
			timeout-low = 3;
			timeout-critical = 0;
			transition-time = 200;
			hide-on-action = true;
			hide-on-clear = false;
			widgets = [ "inhibitors" "title" "dnd" "notifications" ];
			widget-config = {
				title = {
					text = "Notifications";
					clear-all-button = true;
					button-text = "Clear All";
				};
				dnd = { text = "Do Not Disturb"; };
				mpris = {
					image-size = 96;
					image-radius = 12;
				};
			};
		};
	};
}
