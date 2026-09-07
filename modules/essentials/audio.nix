{ ... }:
{
	flake.modules.nixos.audio = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			easyeffects
		];

		# Enable sound.
		services.pipewire = {
			enable = true;
			pulse.enable = true;
			audio.enable = true;
			wireplumber.enable = true;
		};
	};
}