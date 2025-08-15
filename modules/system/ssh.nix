{lib, pkgs, ...}:
{
	programs.ssh = {
		startAgent = true;
	};

	environment.systemPackages = with pkgs; [
		ssh-askpass-fullscreen
		kdePackages.ksshaskpass
	];

}

