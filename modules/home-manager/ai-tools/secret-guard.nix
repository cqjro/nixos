{ ... }:
{
	# Hooks that stop credentials reaching an agent (see docs/secrets.md):
	#   UserPromptSubmit  blocks a message that contains a key/token/private key
	#   PreToolUse        denies file writes / asks on commands carrying one
	# Logic lives in modules/scripts/secret-guard.sh, patterns in
	# modules/scripts/secret-guard-patterns.txt (self-test: secret-guard-test.sh).
	#
	# Lands in the same `programs.claude-code.settings` attrset as claude-code.nix:
	# the module system concatenates the `hooks.<Event>` lists from both files, so
	# adding hooks there does not clobber these. Opt in per host by adding
	# `secret-guard` to the imports of that host's machine.nix.
	flake.modules.homeManager."secret-guard" = { pkgs, ... }:
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
		home.packages = [ guard ];

		programs.claude-code.settings.hooks = {
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
