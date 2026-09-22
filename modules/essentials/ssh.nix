{ ... }:
{
	flake.modules.nixos.ssh = { pkgs, ... }: {
		programs.ssh = {
			startAgent = true;
		};

		environment.systemPackages = with pkgs; [
			# ssh-askpass-fullscreen # removed from nixpkgs unstable; replaced by openssh-askpass
			openssh-askpass
		];
	};
}
