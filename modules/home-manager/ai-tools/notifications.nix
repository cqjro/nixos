{ ... }:
let
	# Hook definitions. `command` is the store path of the agent-notify script
	# (modules/scripts/agent-notify.sh).
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
	# Approval / completion notifications (docs/notifications.md).
	#
	# The managed Claude policy sets `allowManagedHooksOnly`, so hooks come ONLY
	# from `claude-code-policy.hooks` (docs/agents/security.md, "Adding hooks");
	# home-manager `programs.claude-code.settings.hooks` would be ignored. Import
	# this fragment only on hosts that also import `claude-code-policy`
	# (GOD-KILLER, REDRUM); the option does not exist on LittleNix.
	#
	# The hook runs as the agent's user (cairo on GOD-KILLER, t3code on REDRUM,
	# home /var/lib/t3code). The ntfy topic/token are read at run time from
	# ~/.config/agent-notify (docs/notifications.md); nothing secret is in the
	# store or the policy JSON.
	flake.modules.nixos."agent-notifications" = { config, lib, pkgs, ... }:
		let script = mkScript pkgs config.agent-notifications.desktop;
		in {
			options.agent-notifications.desktop = lib.mkOption {
				type = lib.types.bool;
				default = false;
				description = "Also raise a desktop popup (libnotify). True on GOD-KILLER, false on REDRUM.";
			};
			options.agent-notifications.package = lib.mkOption {
				type = lib.types.package;
				readOnly = true;
				default = script;
				description = "The agent-notify script, for systemd units (e.g. a timer as t3code).";
			};
			config = {
				environment.systemPackages = [ script ];
				claude-code-policy.hooks = mkHooks "${script}/bin/agent-notify";
			};
		};
}
