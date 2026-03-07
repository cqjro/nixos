{ pkgs, ... }:
{
	networking = {
		# wireless.iwd.enable = true;

		networkmanager = { 
			enable = true;
			# wifi.backend = "iwd";
			plugins = with pkgs; [
				networkmanager-openconnect
					networkmanager-openvpn
					networkmanager-vpnc
			];
		};
	};

	environment.systemPackages = with pkgs; [
		impala
	];
}
