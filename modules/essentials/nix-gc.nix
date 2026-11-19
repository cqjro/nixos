{ ... }:
{
	# Store hygiene for every host (shared): MENTICIDE filled its disk after a few
	# rebuilds because nothing ever collected old generations. Three layers:
	#
	# 1. Weekly `nh clean all`: drops generations older than 14 days but ALWAYS
	#    keeps the newest 5, so rollback still works on a box nobody can reach
	#    physically (plain `nix.gc.options = "--delete-older-than 14d"` would delete
	#    the previous generation too if the last switch was over two weeks ago).
	#    GC then frees paths once their `result` links are gone (see below).
	#    programs.nh.clean and
	#    nix.gc.automatic are mutually exclusive (nixpkgs warns when both are set),
	#    so nix.gc stays off.
	# 2. min-free/max-free: nix itself collects garbage mid-build when free space
	#    drops under min-free, until max-free is available. A safety net for a big
	#    rebuild between weekly runs; it only removes already-dead paths, never
	#    generations.
	# 3. Weekly store deduplication (hard links) after the clean, instead of
	#    auto-optimise-store, which slows every build.
	#
	# Agents' `./rebuild.sh build` leaves a `result` symlink in the checkout; that
	# is a GC root, so a full system closure per worktree stays alive until the
	# link is removed (delete finished worktrees' `result`).
	flake.modules.nixos."nix-gc" = { ... }: {
		programs.nh.clean = {
			enable = true;
			dates = "Sun 03:00";
			extraArgs = "--keep 5 --keep-since 14d";
		};

		nix.settings = {
			min-free = 5 * 1024 * 1024 * 1024; # start a collection below 5 GiB free
			max-free = 15 * 1024 * 1024 * 1024; # ...and stop at 15 GiB free
		};

		nix.optimise = {
			automatic = true;
			dates = [ "Sun 04:30" ];
		};

		# Laptops and desktops are often off at Sunday 03:00. Both timers are
		# Persistent (nixpkgs default), so a missed run fires at the next boot or
		# wake. nix.optimise already adds a 30 min random delay; give nh-clean the
		# same so the catch-up does not land the instant someone logs in.
		systemd.timers.nh-clean.timerConfig.RandomizedDelaySec = "30min";
	};
}
