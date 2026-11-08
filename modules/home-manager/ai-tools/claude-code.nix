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

				# The permission policy is NOT here: it is the root-owned managed
				# policy below (/etc/claude-code/managed-settings.json), which the
				# agent cannot edit and every user-level file merges under. The
				# merge is `live * nix` and jq replaces arrays wholesale, so these
				# empty lists wipe rules left in the live file by older generations
				# (or written by an agent) on every activation.
				permissions = {
					allow = [];
					ask = [];
					deny = [];
				};
			};
		};
	};

	# Claude Code policy for every user on the host: cairo on GOD-KILLER and the
	# t3code service user on REDRUM read the same file, so the two cannot drift.
	# Layers, strongest first (docs/agents/security.md has the evidence):
	#   1. sandbox: bubblewrap; with blockReadsOutsideWorkingDirectories it
	#      swaps /home for an empty tmpfs and re-opens only the working dirs,
	#      so ~/.ssh, ~/.config/gh, ... do not exist for sandboxed Bash. Strict:
	#      nothing escapes except `excludedCommands`.
	#   2. deny rules + the claude-guard PreToolUse hook: hold in every mode,
	#      including T3 Full access (bypassPermissions).
	#   3. ask rules: prompts in Supervised / Accept edits / Auto. Full access
	#      auto-approves prompts, so the guard turns these into blocks there.
	# Other modules add hooks through the `claude-code-policy.hooks` option
	# (lists concatenate; see docs/agents/security.md, "Adding hooks"), e.g.:
	#   claude-code-policy.hooks.PreToolUse = [ { matcher = "Read"; hooks = [ { type = "command"; command = "${script}/bin/x"; timeout = 10; } ]; } ];
	# Only hooks in this policy run (allowManagedHooksOnly): home-manager
	# `programs.claude-code.settings.hooks` and repo/skill hooks are ignored.
	flake.modules.nixos."claude-code-policy" = { config, lib, pkgs, ... }:
		let
			guard = pkgs.writeShellApplication {
				name = "claude-guard";
				runtimeInputs = with pkgs; [ coreutils gnugrep gnused jq git ];
				text = builtins.readFile ../../scripts/claude-guard.sh;
				# literal `$HOME` / `$(` in its regexes and self-tests are the point
				excludeShellChecks = [ "SC2016" ];
			};

			# commands that run outside the sandbox. They still go through the
			# normal permission flow (allow/ask/deny, guard). Keep them narrow: an
			# excluded command can read everything the user can.
			excludedCommands = [
				# the nix daemon socket is AF_UNIX (blocked by the sandbox's seccomp
				# filter) and flake eval trips over the masked .gitmodules.
				# `nix run/shell/develop` stay sandboxed on purpose (they would
				# execute arbitrary code outside it), so they fail in agent sessions.
				"nix eval *"
				"nix build *"
				"nix flake *"
				"nix log *"
				"nix path-info *"
				"nix why-depends *"
				"nix search *"
				"nix store *"
				"nix derivation *"
				"nix-store *"
				"nix-instantiate *"
				"nixos-rebuild *"
				"./rebuild.sh *"
				# scheduled checks (docs/schedules/README.md): the script runs gh,
				# git and nix itself, so it cannot be sandboxed. The ABSOLUTE path
				# of the main checkout only: ~/.nixos changes by merged PR plus the
				# owner's switch, and claude-guard blocks edits to that file. A
				# worktree copy (relative path) is code the agent can edit and stays
				# sandboxed. The script runs with the gh token that can write issues
				# and labels, so do not widen this pattern. The policy is shared with
				# REDRUM, where /home/cairo is not readable by t3code (inert there).
				"/home/cairo/.nixos/docs/schedules/bin/schedule-precheck *"
				# REDRUM: the same script packaged by the `schedule-precheck` NixOS
				# fragment into the system profile. The path is a root-owned symlink
				# into the store, so (unlike t3code's own checkout) no agent can edit
				# what it runs, and the shared policy needs no bare name on PATH.
				"/run/current-system/sw/bin/schedule-precheck *"
				# theme-shots (modules/theme/theme-shots.nix, GOD-KILLER only; inert on
				# REDRUM, where nothing installs it): renders the generated Zen CSS on
				# four fixed sites in a throwaway headless Firefox. It needs the nix
				# daemon socket (nix eval) and the sites, which strictAllowlist would
				# refuse. Absolute path into the root-owned system profile, so no agent
				# can edit what it runs.
				# Excluded commands are not limited by network.allowedDomains: the
				# script confines Firefox itself (PAC allowlist), see
				# docs/agents/security.md, "theme-shots runs unsandboxed". Do not widen.
				"/run/current-system/sw/bin/theme-shots *"
				# gh and git's network commands need the token in ~/.config/gh
				"gh *"
				"git push *"
				"git fetch *"
				"git pull *"
				"git ls-remote *"
				# D-Bus / unix sockets, /run and the host network namespace
				"systemctl *"
				"journalctl *"
				"loginctl *"
				"resolvectl *"
				"tailscale status *"
				"ss *"
				"ip addr *"
				"ip route *"
				"ip link show *"
				# GPU / display probes (Waydroid, Hyprland troubleshooting)
				"hyprctl monitors *"
				"hyprctl clients *"
				"hyprctl workspaces *"
				"hyprctl devices *"
				"hyprctl version *"
				"nvidia-smi *"
				"vulkaninfo *"
				"glxinfo *"
				"eglinfo *"
				"wayland-info *"
				"mpv *"
				"waydroid *"
				"adb *"
			];

			permissions = {
				# Do NOT set `disableBypassPermissionsMode`: T3 Code launches Full
				# access threads with `--permission-mode bypassPermissions`, which it
				# contradicts (provider error). Deny rules and the guard hold there.

				# reads outside the working directories prompt (file tools and
				# recognised read commands) and, with the sandbox, are hidden from
				# sandboxed Bash. Grant a directory per session with /add-dir.
				blockReadsOutsideWorkingDirectories = true;

				allow = [
					# mcp-nixos (read-only package/option/version lookups). MCP servers
					# delivered by home-manager arrive as the "hm" plugin, hence the prefix.
					"mcp__plugin_hm_nixos__nix"
					"mcp__plugin_hm_nixos__nix_versions"

					# verification that needs no root (rebuild.sh stages that never
					# activate; test/dry/revert/switch/push are ask rules below)
					"Bash(./rebuild.sh check*)"
					"Bash(./rebuild.sh eval *)"
					"Bash(./rebuild.sh build *)"
					"Bash(./rebuild.sh generations*)"
					# scheduled checks: probes upstream, evaluates origin/master in a
					# private clone, files issues; plain command, absolute path
					"Bash(/home/cairo/.nixos/docs/schedules/bin/schedule-precheck *)"
					"Bash(/run/current-system/sw/bin/schedule-precheck *)"
					# before/after screenshots of the generated Zen CSS; plain command,
					# absolute path (docs/agents/theme-shots.md)
					"Bash(/run/current-system/sw/bin/theme-shots *)"
					"Bash(bash -n *)"
					"Bash(nixos-rebuild build *)"
					"Bash(nixos-rebuild list-generations *)"
					"Bash(nix eval *)"
					"Bash(nix build *)"
					"Bash(nix flake check *)"
					"Bash(nix flake metadata *)"
					"Bash(nix flake show *)"
					"Bash(nix search *)"
					"Bash(nix log *)"
					"Bash(nix path-info *)"
					"Bash(nix why-depends *)"
					"Bash(nix derivation show *)"
					"Bash(nix store diff-closures *)"

					# branch work (commits on master prompt via the guard; pushes
					# always prompt: `git push *` is an ask rule)
					"Bash(git add *)"
					"Bash(git commit *)"
					"Bash(git fetch *)"
					"Bash(git ls-remote *)"

					# GitHub: reads, plus PRs/issues on this repo (the guard prompts
					# when --repo names another one)
					"Bash(gh auth status)"
					"Bash(gh issue view *)"
					"Bash(gh issue list *)"
					"Bash(gh issue create *)"
					"Bash(gh pr view *)"
					"Bash(gh pr list *)"
					"Bash(gh pr diff *)"
					"Bash(gh pr checks *)"
					"Bash(gh pr create *)"
					"Bash(gh repo view *)"
					"Bash(gh run list *)"
					"Bash(gh run view *)"
					"Bash(gh release list *)"
					"Bash(gh release view *)"
					"Bash(gh search issues *)"
					"Bash(gh search prs *)"
					"WebFetch(domain:github.com)"
					"WebFetch(domain:raw.githubusercontent.com)"
					"WebFetch(domain:code.claude.com)"
					"WebFetch(domain:nixos.org)"
					"WebFetch(domain:wiki.nixos.org)"
					"WebFetch(domain:search.nixos.org)"
					"WebFetch(domain:discourse.nixos.org)"
					"WebFetch(domain:nix.dev)"
					"WebFetch(domain:wiki.t2linux.org)"

					# on-device troubleshooting (read-only)
					"Bash(journalctl *)"
					"Bash(systemctl status *)"
					"Bash(systemctl is-active *)"
					"Bash(systemctl is-enabled *)"
					"Bash(systemctl is-failed *)"
					"Bash(systemctl list-units *)"
					"Bash(systemctl list-timers *)"
					"Bash(systemctl list-unit-files *)"
					"Bash(systemctl cat *)"
					"Bash(systemctl show *)"
					"Bash(systemctl --user status *)"
					"Bash(systemctl --user list-units *)"
					"Bash(systemctl --user is-active *)"
					"Bash(loginctl list-sessions *)"
					"Bash(loginctl show-session *)"
					"Bash(resolvectl status *)"
					"Bash(tailscale status *)"
					"Bash(ss *)"
					"Bash(ip addr *)"
					"Bash(ip route *)"
					"Bash(ip link show *)"
					"Bash(hyprctl monitors *)"
					"Bash(hyprctl clients *)"
					"Bash(hyprctl workspaces *)"
					"Bash(hyprctl devices *)"
					"Bash(hyprctl version *)"
					"Bash(nvidia-smi *)"
				];

				# consent gates: these prompt in Supervised, Accept edits and Auto;
				# in Full access the guard refuses them instead
				ask = [
					"Bash(sudo *)"
					"Bash(nixos-rebuild switch *)"
					"Bash(nixos-rebuild boot *)"
					"Bash(nixos-rebuild test *)"
					"Bash(nixos-rebuild dry-activate *)"
					# test/dry/revert activate through the sudo askpass
					"Bash(*rebuild.sh switch*)"
					"Bash(*rebuild.sh test*)"
					"Bash(*rebuild.sh dry*)"
					"Bash(*rebuild.sh revert*)"
					"Bash(*rebuild.sh deploy*)"
					"Bash(*rebuild.sh push*)"
					"Bash(git push *)"
					"Bash(git merge *)"
					"Bash(git reset --hard*)"
					"Bash(git clean *)"
					"Bash(git branch -D *)"
					"Bash(git branch -f *)"
					"Bash(git update-ref *)"
					"Bash(git reflog expire *)"
					"Bash(git reflog delete *)"
					"Bash(git gc *)"
					"Bash(git stash drop *)"
					"Bash(git stash clear*)"
					"Bash(git worktree remove *)"
					"Bash(git worktree prune *)"
					# approving this card IS the merge approval (no GitHub review:
					# the owner's token cannot approve its own PR)
					"Bash(gh pr merge *)"
					"Bash(gh pr update-branch *)"
					"Bash(gh pr comment *)"
					"Bash(gh pr close *)"
					"Bash(gh api *)"
					"Bash(gh repo create *)"
					"Bash(gh repo delete *)"
					"Bash(gh repo edit *)"
					"Bash(gh repo rename *)"
					"Bash(gh repo archive *)"
					"Bash(gh release create *)"
					"Bash(gh release delete *)"
					"Bash(gh release upload *)"
					"Bash(gh secret *)"
					"Bash(gh variable *)"
					"Bash(gh workflow run *)"
					"Bash(gh gist *)"
					"Bash(systemctl start *)"
					"Bash(systemctl stop *)"
					"Bash(systemctl restart *)"
					"Bash(systemctl reload *)"
					"Bash(systemctl enable *)"
					"Bash(systemctl disable *)"
					"Bash(systemctl mask *)"
					"Bash(systemctl kill *)"
					"Bash(systemctl --user start *)"
					"Bash(systemctl --user stop *)"
					"Bash(systemctl --user restart *)"
					"Bash(systemctl --user enable *)"
					"Bash(systemctl --user disable *)"
				];

				deny = [
					# gh is git's credential helper (github-cli.nix): never let the
					# agent print the token
					"Bash(gh auth token*)"
					"Bash(gh auth status *)"
					"Bash(gh auth refresh*)"
					"Bash(gh auth login*)"
					"Bash(gh auth logout*)"
					"Bash(gh auth switch*)"
					"Bash(git credential*)"
					"Bash(*hosts.yml*)"

					# human-only: drives the real, logged-in Zen and screenshots your
					# desktop (modules/scripts/zen-shots.sh)
					"Bash(zen-shots*)"
					"Bash(/run/current-system/sw/bin/zen-shots*)"

					# credentials and secrets. Read rules cover Read/Grep/Glob, the
					# Bash file commands Claude recognises (cat, head, sed, ...), and
					# are merged into the sandbox's denyRead
					"Read(~/.ssh/**)"
					"Read(~/.gnupg/**)"
					"Read(~/.config/gh/**)"
					"Read(~/.config/rss-sync/**)"
					"Read(~/.config/agent-notify/**)"
					"Read(~/.config/nix/nix.conf)"
					"Read(~/.git-credentials)"
					"Read(~/.netrc)"
					"Read(~/.claude/.credentials.json)"
					"Read(~/.t3/userdata/secrets/**)"
					"Read(//run/secrets/**)"
					"Read(//etc/ssh/ssh_host_*)"
					"Read(//var/lib/cloudflared/**)"
					"Read(//var/lib/**/*.env)"
					"Read(//var/lib/miniflux/api-token)"
					"Read(//**/.env)"
					"Read(//**/token.json)"
					"Read(//**/client_secret.json)"

					# T2 Broadcom firmware (modules/system/t2-firmware.nix): proprietary,
					# not secret. Agents may name it, never read, copy or attach it.
					# A Read deny also blocks Edit/Write of the path. The first two
					# are also hidden inside the Bash sandbox (absolute paths and
					# single-level globs are expanded into it; leading `**` patterns
					# below only cover the Read/Grep/Glob tools). `*-brcm-firmware*` covers
					# the import, the copy and the `-zstd` copy behind /run/current-system/firmware.
					"Read(//var/lib/firmware-src/**)"
					"Read(//nix/store/*-brcm-firmware*/**)"
					"Read(//**/firmware/brcm/**)"
					"Read(//**/brcmfmac*)"
					"Read(//**/brcmbt*)"
					"Read(//**/*.clm_blob)"
					"Read(//**/*.txcap_blob)"
					"Read(//**/*.ptb)"
					"Read(//**/firmware.tar*)"
					"Read(//**/brcm-firmware.gcroot)"

					# the agent must not widen its own permissions or touch keys:
					# settings, hooks and MCP servers in a repo run on the next session
					"Edit(~/.ssh/**)"
					"Edit(~/.gnupg/**)"
					"Edit(~/.claude/settings.json)"
					"Edit(~/.claude/settings.local.json)"
					"Edit(**/.claude/settings.json)"
					"Edit(**/.claude/settings.local.json)"
					"Edit(**/.claude/hooks/**)"
					"Edit(**/.mcp.json)"
					"Edit(//etc/claude-code/**)"
					"Edit(~/.t3/userdata/**)"

					# persistence outside the sandbox: things that run later as the
					# user. Supervised already prompts (protected paths); these hold
					# in Full access too, where the Edit tool may write anywhere.
					"Edit(~/.zshrc)"
					"Edit(~/.zshenv)"
					"Edit(~/.zprofile)"
					"Edit(~/.bashrc)"
					"Edit(~/.bash_profile)"
					"Edit(~/.profile)"
					"Edit(~/.gitconfig)"
					"Edit(~/.config/git/**)"
					"Edit(~/.config/systemd/**)"
					"Edit(~/.config/autostart/**)"
					"Edit(~/.config/hypr/**)"
					"Edit(~/.local/bin/**)"
				];
			};

			askRules = pkgs.writeText "claude-ask-rules.json" (builtins.toJSON permissions.ask);
		in {
			options.claude-code-policy.hooks = lib.mkOption {
				type = lib.types.attrsOf (lib.types.listOf (lib.types.attrsOf lib.types.anything));
				default = { };
				example = lib.literalExpression ''{ Stop = [ { hooks = [ { type = "command"; command = "''${script}/bin/notify"; timeout = 10; } ]; } ]; }'';
				description = ''
					Claude Code hooks by event name, written into the managed policy.
					Definitions from several modules concatenate per event. With
					`allowManagedHooksOnly` this is the only place a hook can come from.
					Commands run outside the sandbox as the session's user, so use
					store paths, never a path in the repo or the home directory.
				'';
			};

			config = {
				claude-code-policy.hooks.PreToolUse = lib.mkBefore [
					{
						matcher = "Bash|Edit|Write|MultiEdit|NotebookEdit";
						hooks = [
							{
								type = "command";
								command = "${guard}/bin/claude-guard ${askRules}";
								timeout = 10;
							}
						];
					}
				];

				# sandbox runtime (the T3 Code package wraps these into its own PATH;
				# a terminal `claude` needs them system-wide). The REDRUM service PATH
				# is set in modules/server/t3code.nix.
				environment.systemPackages = [ pkgs.bubblewrap pkgs.socat guard ];

				environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
					inherit permissions;

					# only hooks from /etc/claude-code (root-owned, from this repo) run:
					# hooks an agent writes into a repo's .claude/settings.json, a skill
					# or a subagent never execute. Also disables /goal and user-level
					# statusLine.
					allowManagedHooksOnly = true;

					inherit (config.claude-code-policy) hooks;

					sandbox = {
						enabled = true;
						# refuse to start rather than silently run unsandboxed
						failIfUnavailable = true;
						# strict: no `dangerouslyDisableSandbox` retries
						allowUnsandboxedCommands = false;
						# sandboxed Bash runs without a prompt; content ask rules
						# (git push, rm of .git via the guard, ...) still prompt
						autoAllowBashIfSandboxed = true;
						inherit excludedCommands;
						# home is hidden from sandboxed commands; git still needs its
						# config (identity, gh credential-helper line; no secrets in it)
						filesystem.allowRead = [ "~/.config/git" ];
						# hosts sandboxed commands (curl, git over https, ...) may reach.
						# Strict: anything else is refused instead of prompting, because
						# Full access auto-approves that prompt (curl example.com went
						# through in a bypass test). Does not limit WebFetch, MCP or
						# excluded commands.
						network.strictAllowlist = true;
						network.allowedDomains = [
							"github.com"
							"api.github.com"
							"codeload.github.com"
							"raw.githubusercontent.com"
							"objects.githubusercontent.com"
							"cache.nixos.org"
							"channels.nixos.org"
							"nixos.org"
							"search.nixos.org"
							"wiki.t2linux.org"
						];
					};
				};
			};
		};
}
