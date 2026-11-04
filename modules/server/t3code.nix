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
			mainPkgs = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
			t3code = mainPkgs.t3code;
			# T3 only offers a Claude model when the `claude` CLI is new enough for
			# it (per-model minVersion in its catalog). The pinned nixpkgs ships
			# claude-code 2.1.238, which leaves only the legacy model available.
			# TODO-remove: use `pkgs.claude-code` again once the pin is lifted.
			# claude-code is unfree and `legacyPackages` ignores the host's config
			claude-code = (import inputs.nixpkgs {
				inherit (pkgs.stdenv.hostPlatform) system;
				inherit (config.nixpkgs) config;
			}).claude-code;
		in {
		users.users.${appUser} = {
			isSystemUser = true;
			group = appUser;
			home = workDir;
			createHome = true;
			# read every unit's journal for troubleshooting (`systemctl status`
			# already works for any user over D-Bus). Read-only: no polkit rights,
			# no sudo, and /home/cairo stays out of reach (0700).
			extraGroups = [ "systemd-journal" ];
		};
		users.groups.${appUser} = {};

		# `claude` / `gh` for the t3code user to log in once by hand
		# (`sudo -u t3code -H claude`, `sudo -u t3code -H gh auth login`) and `t3`
		# for `t3 pair`; git is already in the REDRUM system profile.
		environment.systemPackages = [ claude-code pkgs.gh t3code ];

		# The server only drives a provider, it does not ship one: everything the
		# agent shells out to has to be on the unit's PATH. Credentials live in
		# ${workDir}/.claude and ${workDir}/.config/gh (created by the logins above,
		# never in the Nix store).
		systemd.services.t3code = {
			description = "T3 Code server";
			after = [ "network.target" ];
			wantedBy = [ "multi-user.target" ];
			# bubblewrap + socat: Claude Code's sandbox (the managed policy sets
			# failIfUnavailable, so `claude` refuses to start without them)
			path = [ claude-code pkgs.gh pkgs.git pkgs.bashInteractive config.nix.package pkgs.bubblewrap pkgs.socat ];

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
					"GIT_CONFIG_COUNT=3"
					"GIT_CONFIG_KEY_0=credential.https://github.com.helper"
					"GIT_CONFIG_VALUE_0=!${pkgs.gh}/bin/gh auth git-credential"
					# commit identity (same as cairo's on GOD-KILLER); env, not a
					# config file, so it also reaches the agent's sandboxed git
					"GIT_CONFIG_KEY_1=user.name"
					"GIT_CONFIG_VALUE_1=cqjro"
					"GIT_CONFIG_KEY_2=user.email"
					"GIT_CONFIG_VALUE_2=108373187+cqjro@users.noreply.github.com"
				];
				ExecStart = "${t3code}/bin/t3 serve --host 127.0.0.1 --port ${toString port}";
				Restart = "on-failure";
				RestartSec = 5;
			};
		};

		# The agent's Claude Code policy is the shared managed policy
		# (`claude-code-policy`, modules/home-manager/ai-tools/claude-code.nix,
		# added to REDRUM in modules/hosts/host.nix): the same rules as the
		# desktop, read by every user from /etc/claude-code. `~/` in its rules is
		# ${workDir} for this user, so the gh token and Claude login stay denied.

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
