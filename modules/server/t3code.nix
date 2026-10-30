{ ... }:
let
	appUser = "t3code";
	workDir = "/var/lib/t3code";
	# 8086 is the ABT sidecar (actual-budget-tweaks.nix), 8087 is reserved for
	# audiobookshelf (TODO.md).
	port = 8088;
in
{
	flake.modules.nixos.t3code = { config, inputs, pkgs, lib, ... }:
		let
			# The desktop client refuses servers older than itself ("This client
			# requires a newer server"). REDRUM's pinned nixpkgs
			# (modules/hosts/REDRUM/T2-PIN.md) ships t3code 0.0.33, so the server
			# comes from the main `nixpkgs` input, the same build GOD-KILLER runs.
			# TODO-remove: use `pkgs.t3code` again once the pin is lifted.
			t3code = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.t3code;
		in {
		users.users.${appUser} = {
			isSystemUser = true;
			group = appUser;
			home = workDir;
			createHome = true;
		};
		users.groups.${appUser} = {};

		# `claude` / `gh` for the t3code user to log in once by hand
		# (`sudo -u t3code -H claude`, `sudo -u t3code -H gh auth login`) and `t3`
		# for `t3 pair`; git is already in the REDRUM system profile.
		environment.systemPackages = [ pkgs.claude-code pkgs.gh t3code ];

		# The server only drives a provider, it does not ship one: everything the
		# agent shells out to has to be on the unit's PATH. Credentials live in
		# ${workDir}/.claude and ${workDir}/.config/gh (created by the logins above,
		# never in the Nix store).
		systemd.services.t3code = {
			description = "T3 Code server";
			after = [ "network.target" ];
			wantedBy = [ "multi-user.target" ];
			path = [ pkgs.claude-code pkgs.gh pkgs.git pkgs.bashInteractive config.nix.package ];

			serviceConfig = {
				Type = "simple";
				User = appUser;
				Group = appUser;
				WorkingDirectory = workDir;
				Environment = [
					"HOME=${workDir}"
					"XDG_DATA_HOME=${workDir}/.local/share"
					"XDG_CONFIG_HOME=${workDir}/.config"
					# systemd sets $SHELL to the user's login shell, which is nologin for
					# a system user; the agent's Bash tool needs a real one
					"SHELL=${pkgs.bashInteractive}/bin/bash"
					# gh as git's credential helper for this service only (same idea as
					# modules/home-manager/ai-tools/github-cli.nix, without touching
					# cairo's git config): HTTPS pushes with the token from `gh auth login`
					"GIT_CONFIG_COUNT=1"
					"GIT_CONFIG_KEY_0=credential.https://github.com.helper"
					"GIT_CONFIG_VALUE_0=!${pkgs.gh}/bin/gh auth git-credential"
				];
				ExecStart = "${t3code}/bin/t3 serve --host 127.0.0.1 --port ${toString port}";
				Restart = "on-failure";
				RestartSec = 5;
			};
		};

		# Managed Claude Code policy for the agent running as t3code (the
		# home-manager policy in ai-tools/claude-code.nix only reaches cairo on
		# GOD-KILLER). Linux reads /etc/claude-code/managed-settings.json for every
		# user. Shorter than the desktop list: this user has no sudo, so the point is
		# keeping the gh token unreadable and gating anything that leaves the box.
		environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
			permissions = {
				# meant to fall back to asking instead of bypassing (T3's Full access).
				# Unverified at the managed level; at the user level it did NOT hold
				# (AGENTS.md "Consent model") — keep REDRUM threads on Supervised.
				disableBypassPermissionsMode = "disable";
				blockReadsOutsideWorkingDirectories = true;

				allow = [
					"Bash(systemctl status *)"
					"Bash(systemctl is-active *)"
					"Bash(systemctl cat *)"
					"Bash(gh issue view *)"
					"Bash(gh issue list *)"
					"Bash(gh pr view *)"
					"Bash(gh pr list *)"
					"Bash(gh pr checks *)"
					"Bash(gh repo view *)"
				];

				ask = [
					"Bash(sudo *)"
					"Bash(git commit *)"
					"Bash(git push *)"
					"Bash(gh pr merge *)"
					"Bash(gh pr create *)"
					"Bash(gh api *)"
				];

				deny = [
					# the gh token and Claude login sit in ${workDir}; never print them
					"Bash(gh auth token*)"
					"Bash(gh auth status *)"
					"Bash(gh auth refresh*)"
					"Bash(gh auth login*)"
					"Bash(gh auth logout*)"
					"Bash(gh auth switch*)"
					"Bash(git credential*)"
					"Bash(*hosts.yml*)"
					"Read(~/.config/gh/**)"
					"Read(~/.claude/.credentials.json)"
					"Read(//var/lib/**/*.env)"
					"Read(//var/lib/cloudflared/**)"
					"Read(//**/.env)"
					"Read(//etc/ssh/ssh_host_*)"
				];
			};
		};

		# Reached over the tailnet only (no Cloudflare tunnel): Tailscale Serve
		# publishes the loopback server on https://<magicdns-name>/ . `tailscale
		# serve` needs root/operator rights and persists in tailscaled's state, so
		# it runs as a root oneshot rather than as the t3code user.
		systemd.services.t3code-tailscale-serve = {
			description = "Publish the T3 Code server over Tailscale Serve";
			after = [ "tailscaled.service" "t3code.service" ];
			wants = [ "tailscaled.service" ];
			wantedBy = [ "multi-user.target" ];

			serviceConfig = {
				Type = "oneshot";
				RemainAfterExit = true;
				ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --https=443 http://127.0.0.1:${toString port}";
				ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --https=443 off";
				# fails until the node is logged in to the tailnet; keep retrying
				Restart = "on-failure";
				RestartSec = 15;
			};
		};
	};
}
