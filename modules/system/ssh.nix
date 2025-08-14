{lib, pkgs, ...}:
{
	programs.ssh = {
		startAgent = true;
		askPassword = lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
	};
}

