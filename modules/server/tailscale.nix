{ ... }:
{
	flake.modules.nixos.tailscale = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			tailscale
		];

		services.tailscale = {
			enable = true;
		};
	};
}