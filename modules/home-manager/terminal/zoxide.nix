{pkgs, lib, config, inputs, ...}:
{
	programs.zoxide = {
		enable = true;
		enableZshIntegration = true;
	};

}
