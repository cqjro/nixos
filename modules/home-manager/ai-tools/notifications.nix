{ ... }:
let
	# Hook definitions shared by both fragments. `command` is the store path of
	# the agent-notify script (modules/scripts/agent-notify.sh).
	mkHooks = command: let
		entry = matcher: {
			inherit matcher;
			hooks = [ { type = "command"; inherit command; timeout = 20; } ];
		};
	in {
		# permission_prompt: Claude Code is waiting on an approval; the others are
		# questions put to the user. idle_prompt is deliberately left out: it
		# fires ~60s after a Stop and would duplicate the completion push.
		Notification = [ (entry "permission_prompt|elicitation_dialog|agent_needs_input") ];
		Stop = [ (entry "") ];
		StopFailure = [ (entry "") ];
		# PermissionRequest carries the actual command, which lets the script rank
		# the approvals that matter (gh pr merge, rebuild.sh switch|test, pushes).
		# It returns no decision, so the normal prompt flow is untouched. The
		# generic permission_prompt Notification stays as the fallback in case
		# PermissionRequest does not fire under T3; the script dedupes the pair.
		PermissionRequest = [ (entry "") ];
	};

	mkScript = pkgs: desktop: pkgs.writeShellApplication {
		name = "agent-notify";
		runtimeInputs = [ pkgs.jq pkgs.curl pkgs.git pkgs.coreutils pkgs.findutils pkgs.gnused ]
			++ pkgs.lib.optional desktop pkgs.libnotify;
		text = builtins.readFile ../../scripts/agent-notify.sh;
		# the script is written defensively on purpose (every path exits 0)
		excludeShellChecks = [ "SC2015" ];
	};
in
{
	# User side (GOD-KILLER, or any host with home-manager). Adds hooks to the
	# same programs.claude-code.settings that ai-tools/claude-code.nix defines;
	# the module system merges the two, so claude-code.nix is not edited.
	flake.modules.homeManager."agent-notifications" = { lib, pkgs, ... }:
		let script = mkScript pkgs true;
		in {
			options.programs.agent-notify.package = lib.mkOption {
				type = lib.types.package;
				readOnly = true;
				default = script;
				description = "The agent-notify script, for user timers.";
			};
			config.home.packages = [ script ];
			config.programs.claude-code.settings.hooks = mkHooks "${script}/bin/agent-notify";
		};

	# System side (REDRUM's t3code user, which home-manager never reaches). Puts
	# the script on the system profile and exposes the hook set as
	# `config.agentNotifications.hooks` for t3code.nix's managed-settings.json.
	# Handoff to the permissions owner: merge it in with
	#   hooks = config.agentNotifications.hooks;
	# (see docs/notifications.md, "REDRUM").
	flake.modules.nixos."agent-notifications" = { config, lib, pkgs, ... }:
		let script = mkScript pkgs false;
		in {
			options.agentNotifications.hooks = lib.mkOption {
				type = lib.types.attrs;
				readOnly = true;
				default = mkHooks "${script}/bin/agent-notify";
				description = "Claude Code hooks for agent-notify, for managed-settings.json.";
			};
			options.agentNotifications.package = lib.mkOption {
				type = lib.types.package;
				readOnly = true;
				default = script;
				description = "The agent-notify script, for systemd units (e.g. a timer as t3code).";
			};
			config.environment.systemPackages = [ script ];
		};
}
