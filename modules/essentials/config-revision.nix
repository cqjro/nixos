{ inputs, ... }:
{
	# Stamps every generation with the git commit it was built from, so
	# `nixos-rebuild list-generations` (Configuration Revision column),
	# `nixos-version --configuration-revision` and the boot menu label map a
	# generation back to its commit (and, for squash merges, its PR).
	# `./rebuild.sh generations` prints each generation with that commit's subject.
	# A build from a tree with uncommitted changes gets the parent commit plus
	# a "-dirty" suffix.
	flake.modules.nixos.config-revision = let
		rev = inputs.self.rev or inputs.self.dirtyRev or "unknown";
		shortRev = inputs.self.shortRev or inputs.self.dirtyShortRev or "unknown";
	in {
		system.configurationRevision = rev;
		system.nixos.tags = [ "git-${shortRev}" ];
	};
}
