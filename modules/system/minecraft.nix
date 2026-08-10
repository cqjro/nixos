{ pkgs, ... }:
{

environment.systemPackages = with pkgs; [
	prismlauncher
	modrinth-app	
];

}
