{ ... }:
{
	# Hooks that stop credentials reaching an agent (see docs/secrets.md):
	#   UserPromptSubmit  blocks a message that contains a key/token/private key
	#   PreToolUse        denies file writes / asks on commands carrying one, and
	#                     guards the T2 firmware paths (ask; deny under Full access)
	# Logic lives in modules/scripts/secret-guard.sh, patterns in
	# modules/scripts/secret-guard-patterns.txt (self-test: secret-guard-test.sh).
	#
	# The managed Claude policy sets `allowManagedHooksOnly`, so hooks are read ONLY
	# from `claude-code-policy.hooks` (claude-code.nix, docs/agents/security.md
	# "Adding hooks (merge point)"); home-manager `programs.claude-code.settings.hooks`
	# and project/skill hooks are ignored. Lists concatenate across modules and
	# `claude-guard` stays first in PreToolUse.
	#
	# Import this fragment only on hosts that also import `claude-code-policy`
	# (GOD-KILLER, REDRUM); the option does not exist on LittleNix.
	flake.modules.nixos."secret-guard" = { pkgs, ... }:
	let
		guard = pkgs.writeShellApplication {
			name = "secret-guard";
			runtimeInputs = with pkgs; [ jq gnugrep coreutils ];
			text = ''
				export SECRET_GUARD_PATTERNS=${../../scripts/secret-guard-patterns.txt}
				${builtins.readFile ../../scripts/secret-guard.sh}
			'';
		};
	in
	{
		# command paths are store paths: hooks run outside the sandbox as the
		# session's user, and the JSON is world-readable (no secret in it)
		claude-code-policy.hooks = {
			UserPromptSubmit = [
				{
					hooks = [
						{
							type = "command";
							command = "${guard}/bin/secret-guard prompt";
							timeout = 10;
						}
					];
				}
			];
			PreToolUse = [
				{
					matcher = "Bash|Write|Edit|MultiEdit|NotebookEdit|Read|Grep|Glob";
					hooks = [
						{
							type = "command";
							command = "${guard}/bin/secret-guard tool";
							timeout = 10;
						}
					];
				}
			];
		};
	};
}
