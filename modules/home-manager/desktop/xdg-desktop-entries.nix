{pkgs, lib, config, inputs, ...}:
{
	xdg.desktopEntries = {
		vesktop = {	
			name="Vesktop";
			categories =["Network" "InstantMessaging" "Chat"];
			exec ="vesktop --ozone-platform-hint=wayland %U";
			genericName="Internet Messenger";
			icon ="vesktop";
			# keywords = ["discord" "vencord" "electron" "chat"];
			# startupWMClass = "Vesktop";
			type = "Application";
			# version = 1.4;
		};
	};
}	
