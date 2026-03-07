{lib, config, ...}:
{

	options = {
		school-wifi = lib.mkEnableOption "enable school wifi";
	};

	config = lib.mkIf config.nvidia.enable {
		networking.networkmanager.ensureProfiles.profiles = {
			eduroam = {
				connection = {
					id = "eduroam";
					type = "wifi";
					interface-name = "wlan0";
				};
				wifi = {
					mode = "infrastructure";
					ssid = "eduroam";
				};
				wifi-security = {
					key-mgmt = "wpa-eap";
				};
				"802-1x" = {
					eap = "PEAP";
					identity = "anonymous201891@utoronto.ca";
					client-cert = "/var/lib/iwd/ca.pem";
					private-key = "";
					private-key-password = "";
					ca-cert = "/var/lib/iwd/ca.pem";
				};
				ipv4 = {
					method = "auto";
				};
				ipv6 = {
					method = "auto";
				};
			};

			# Uoft = {};
		};
	};



}
