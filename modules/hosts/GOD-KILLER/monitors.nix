{ ... }:
{
	flake.modules.nixos."GOD-KILLER-monitors" = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			ddcutil
		];
	};

	flake.modules.homeManager."GOD-KILLER-monitors" = {
		hyprland.bindel = [
			",XF86MonBrightnessUp,   exec, ddcutil setvcp 10 + 5 --bus 9 --noverify --sleep-multiplier 0.1 && ddcutil setvcp 10 + 5 --bus 10 --noverify --sleep-multiplier 0.1"
			",XF86MonBrightnessDown, exec, ddcutil setvcp 10 - 5 --bus 9 --noverify --sleep-multiplier 0.1 && ddcutil setvcp 10 - 5 --bus 10 --noverify --sleep-multiplier 0.1"
		];
	};
}
