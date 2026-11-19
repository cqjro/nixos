{ ... }:
{
	flake.modules.nixos.minecraft = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			prismlauncher
			# TODO-remove: nixos-unstable's modrinth-app-unwrapped (0.21.6) does not link
			# (`cannot find -lsqlite3`): its buildInputs lack sqlite. nixpkgs master already
			# adds it; drop the override once that reaches nixos-unstable.
			(modrinth-app.override {
				modrinth-app-unwrapped = modrinth-app-unwrapped.overrideAttrs (old: {
					buildInputs = (old.buildInputs or [ ]) ++ [ sqlite ];
				});
			})
		];
	};
}
