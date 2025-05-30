{pkgs, lib, config, inputs, ...}:
{
	programs.vesktop = {
		enable = true;
		settings = {
			minimizeToTray = false;
						
		};
	};	
}

