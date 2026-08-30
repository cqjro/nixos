{pkgs, ...}:
{
	programs.ssh = {
		startAgent = true;
	};

	environment.systemPackages = with pkgs; [
		# ssh-askpass-fullscreen # removed from nixpkgs unstable for some reason?
		kdePackages.ksshaskpass
	];

}

