{ ... }:
{
	flake.modules.homeManager."claude-code" = { ... }: {
		programs.claude-code = {
			enable = true;
			# fold programs.mcp.servers (see mcp-servers.nix) into Claude Code
			enableMcpIntegration = true;
			# merge into a writable ~/.claude/settings.json instead of a read-only
			# store symlink: Claude Code writes /config choices back into it
			mutableSettings = true;

			settings = {
				theme = "dark";

				permissions = {
					# Do NOT set `disableBypassPermissionsMode` here. T3 Code launches
					# Full access threads with `--permission-mode bypassPermissions
					# --allow-dangerously-skip-permissions`, which contradicts it and
					# makes those threads fail with a provider error. It never gated
					# anything anyway (a Full access thread ran `git push` with no
					# prompt, 2026-10-30): keep threads on Supervised instead.

					# opencode-style `external_directory`: file tools already prompt
					# outside the working directory, but read-only Bash (ls, cat, grep,
					# find) does not unless this is set.
					blockReadsOutsideWorkingDirectories = true;

					# no standing additionalDirectories: grant a directory per session
					# with /add-dir (or the T3 approval card) when troubleshooting
					# another project.

					allow = [
						# mcp-nixos (read-only package/option/version lookups). MCP servers
						# delivered by home-manager arrive as the "hm" plugin, hence the prefix.
						"mcp__plugin_hm_nixos__nix"
						"mcp__plugin_hm_nixos__nix_versions"

						# verification that needs no root
						"Bash(./rebuild.sh build *)"
						"Bash(bash -n *)"
						"Bash(nixos-rebuild list-generations *)"
						"Bash(nix flake metadata *)"
						"Bash(nix flake show *)"
						"Bash(nix search *)"
						"Bash(nix log *)"
						"Bash(nix path-info *)"
						"Bash(nix why-depends *)"
						"Bash(nix store diff-closures *)"

						# on-device troubleshooting (read-only)
						"Bash(journalctl *)"
						"Bash(systemctl status *)"
						"Bash(systemctl is-active *)"
						"Bash(systemctl is-enabled *)"
						"Bash(systemctl list-units *)"
						"Bash(systemctl cat *)"
						"Bash(systemctl --user status *)"

						# upstream-fix checks (AGENTS.md "Pending upstream fixes")
						"Bash(gh auth status)"
						"Bash(gh issue view *)"
						"Bash(gh issue list *)"
						"Bash(gh pr view *)"
						"Bash(gh pr list *)"
						"Bash(gh pr checks *)"
						"Bash(gh repo view *)"
						"WebFetch(domain:github.com)"
						"WebFetch(domain:raw.githubusercontent.com)"
					];

					# consent gates: these prompt even in Auto-accept edits / Auto
					ask = [
						"Bash(sudo *)"
						"Bash(nixos-rebuild switch *)"
						"Bash(nixos-rebuild boot *)"
						"Bash(nixos-rebuild test *)"
						"Bash(*rebuild.sh switch*)"
						"Bash(*rebuild.sh push*)"
						"Bash(git commit *)"
						"Bash(git push *)"
						"Bash(gh pr merge *)"
						"Bash(gh pr create *)"
						"Bash(gh api *)"
					];

					deny = [
						# gh is git's credential helper (github-cli.nix): never let the
						# agent print the token. Best-effort globs; the real gates are the
						# `git push` / `gh api` ask rules above and Supervised mode.
						"Bash(gh auth token*)"
						"Bash(gh auth status *)"
						"Bash(gh auth refresh*)"
						"Bash(gh auth login*)"
						"Bash(gh auth logout*)"
						"Bash(gh auth switch*)"
						"Bash(git credential*)"
						"Bash(*hosts.yml*)"

						# credentials and secrets (Read rules also cover Grep/Glob)
						"Read(~/.ssh/**)"
						"Read(~/.gnupg/**)"
						"Read(~/.config/gh/**)"
						"Read(~/.config/rss-sync/**)"
						"Read(~/.config/nix/nix.conf)"
						"Read(~/.claude/.credentials.json)"
						"Read(~/.t3/userdata/secrets/**)"
						"Read(//run/secrets/**)"
						"Read(//etc/ssh/ssh_host_*)"
						"Read(//var/lib/**/*.env)"
						"Read(//**/.env)"
						"Read(//**/token.json)"
						"Read(//**/client_secret.json)"

						# the agent must not widen its own permissions or touch keys
						"Edit(~/.ssh/**)"
						"Edit(~/.gnupg/**)"
						"Edit(~/.claude/settings.json)"
					];
				};
			};
		};
	};
}
