{ ... }:
{
	flake.modules.nixos.ssh = { pkgs, lib, ... }: {
		programs.ssh = {
			startAgent = true;
		};

		environment.systemPackages = with pkgs; [
			# ssh-askpass-fullscreen # removed from nixpkgs unstable; replaced by openssh-askpass
			openssh-askpass
		];

		# openssh-askpass exposes its gtk-ssh-askpass dialog under libexec/,
		# which the system profile doesn't merge by default — link it so
		# start.sh can find it at /run/current-system/sw/libexec/gtk-ssh-askpass.
		environment.pathsToLink = lib.mkAfter [ "/libexec" ];
	};
}
