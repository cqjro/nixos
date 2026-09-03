{ inputs, pkgs, config, ...}:
let
	c = config.lib.stylix.colors.withHashtag;
in
{
	imports = [
		inputs.noctalia-greeter.nixosModules.default
	];

	programs.noctalia-greeter = {
		enable = true;

		greeter-args = "--session hyprland";

		settings = {
			cursor = {
				theme = "rose-pine-cursor";
				size = 27;
				path = "${pkgs.rose-pine-cursor}/share/icons";
			};	

			keyboard = {
				layout = "us";
			};

			appearance.palette = {
        primary            = c.base0D; # blue/accent
        on_primary         = c.base00; # bg
        secondary          = c.base0C; # cyan
        on_secondary       = c.base00;
        tertiary           = c.base0B; # green
        on_tertiary        = c.base00;
        error              = c.base08; # red
        on_error           = c.base00;
        surface            = c.base00; # bg
        on_surface         = c.base05; # fg
        surface_variant    = c.base01; # bg1
        on_surface_variant = c.base04; # fg dim
        outline            = c.base03;
        shadow             = c.base00;
        hover              = c.base0B;
        on_hover           = c.base00;
      };

		};

	};
	
}
