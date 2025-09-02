{...}:
{
	xdg.desktopEntries = {
		vesktop = {	
			name = "Vesktop";
			categories = ["Network" "InstantMessaging" "Chat"];
			exec = "vesktop --enable-features=WebRTCPipeWireCapturer --ozone-platform-hint=wayland %U";
			genericName = "Internet Messenger";
			icon = "vesktop";
			# keywords = ["discord" "vencord" "electron" "chat"];
			# startupWMClass = "Vesktop";
			type = "Application";
			# version = 1.4;
		};

		# proton-mail = {
		# 	name = "Proton Mail";
		# 	comment = "Proton official desktop application for Proton Mail and Proton Calendar";
		# 	genericName = "Proton Mail";
		# 	exec = "proton-mail --ozone-platform-hint=wayland %U";
		# 	icon = "proton-mail";
		# 	type = "Application";
		# 	# startupNotify = "true";
		# 	categories = ["Network" "Email"];
		# 	# mimeType="x-scheme-handler/mailto";
		# };
	};
}
