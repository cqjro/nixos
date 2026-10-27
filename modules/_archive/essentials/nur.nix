{ inputs, ... }:
{
	# Nix User Repository (NUR): a registry of community-maintained packages
	# that have not (yet) landed in nixpkgs. Importing NUR's own module applies
	# its overlay, so every package is reachable as
	# `pkgs.nur.repos.<repo>.<package>`.
	#
	# Hosts opt in by adding `inputs.self.modules.nixos.nur` to their module
	# list. Because the desktop hosts set `useGlobalPkgs = true`, the same
	# `pkgs.nur...` attributes are also available inside home-manager modules.
	# See the "Nix User Repository (NUR)" section of the README.
	flake.modules.nixos.nur = {
		imports = [ inputs.nur.modules.nixos.default ];
	};
}
