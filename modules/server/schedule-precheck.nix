{ inputs, ... }:
{
	# `schedule-precheck` (docs/schedules/bin/schedule-precheck) packaged into the
	# system profile, so the REDRUM scheduled threads can run it as
	# /run/current-system/sw/bin/schedule-precheck: an absolute path an agent
	# cannot edit (the policy excludes it from the sandbox and allow-lists it,
	# modules/home-manager/ai-tools/claude-code.nix). The script and the JSON files it
	# reads beside it are copied from the flake source, so they are the version of
	# the REDRUM generation: a merged probe change reaches REDRUM's schedules after
	# the next REDRUM switch. gh, git and nix come from the system profile
	# (the script sets its own fixed PATH); only python3 is wrapped in.
	flake.modules.nixos."schedule-precheck" = { pkgs, ... }:
	let
		src = "${inputs.self}/docs/schedules";
		schedule-precheck = pkgs.runCommand "schedule-precheck" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
			dir=$out/libexec/schedule-precheck
			mkdir -p $dir/bin $out/bin
			cp ${src}/bin/schedule-precheck $dir/bin/schedule-precheck
			cp ${src}/upstream-probes.json ${src}/host-scopes.json $dir/
			# the script locates its JSON files from its own resolved path
			makeWrapper ${pkgs.python3}/bin/python3 $out/bin/schedule-precheck \
				--add-flags "-I $dir/bin/schedule-precheck"
		'';
	in {
		environment.systemPackages = [ schedule-precheck ];
	};
}
