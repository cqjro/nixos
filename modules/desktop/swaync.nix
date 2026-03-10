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
		style = ''
			.notification-window {
				margin-top: 55px;
				margin-right: 15px;
			}

			.notification {
				border: 5px solid @base05;
			}

			.notification.low {
				border: 5px solid @base05;
			}

			.notification.normal {
				border: 5px solid @base05;
			}

			.notification.critical {
				border: 5px solid @base05;
			}
		'';
	};
}
