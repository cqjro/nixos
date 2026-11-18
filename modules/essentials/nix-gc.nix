{ ... }:
{
	# Regular garbage collection so the store cannot slowly fill a disk (a build
	# on MENTICIDE once did). Weekly GC drops generations older than 30 days;
	# min-free/max-free also GC during a build when free space drops too low.
	flake.modules.nixos.nix-gc = { lib, ... }: {
		nix.gc = {
			automatic = true;
			dates = "weekly";
			persistent = true;
			options = "--delete-older-than 30d";
		};
		nix.settings = {
			min-free = lib.mkDefault (5 * 1024 * 1024 * 1024); # start GC below 5 GiB free
			max-free = lib.mkDefault (20 * 1024 * 1024 * 1024); # ...until 20 GiB are free
		};
	};
}
