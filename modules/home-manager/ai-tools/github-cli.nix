{ ... }:
{
	flake.modules.homeManager."github-cli" = { pkgs, ... }: {
		home.packages = with pkgs; [
			gh
			git
		];

		programs.gh = {
			enable = true;
			# push/pull over HTTPS through gh's credential helper, so agents (T3 Code
			# -> Claude Code) can push without an ssh-agent or any read access to ~/.ssh
			gitCredentialHelper.enable = true;
			settings = {
				git_protocol = "https";
			};
		};
	};
}
