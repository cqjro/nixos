{ pkgs, ... }:
{
	networking.networkmanager.plugins = with pkgs; [
		networkmanager-openconnect
		networkmanager-openvpn
		networkmanager-vpnc
	];
}
