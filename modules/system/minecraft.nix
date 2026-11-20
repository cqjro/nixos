{ ... }:
{
	flake.modules.nixos.minecraft = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			prismlauncher
		];
	};
}
