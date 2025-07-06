{ pkgs, ... }:
{
	# Install keyd
	environment.systemPackages = with pkgs; [
		keyd
	];	

	# Enable the keyd system service
	services.keyd = {
		enable = true;

		keyboards.default = {
			ids = [ "*" ]; # Match all keyboards

			settings = {
				main = {
					# Home row mods - left hand
					a = "overloadt(meta, a, 500)";
					s = "overloadt(alt, s, 500)";
					d = "overloadt(shift, d, 500)";
					f = "overloadt(control, f, 500)";

					# Home row mods - right hand
					j = "overloadt(control, j, 500)";
					k = "overloadt(shift, k, 500, 500)";
					l = "overloadt(alt, l, 500)";
					semicolon = "overloadt(meta, semicolon, 500)";

					# overload_timeout = "800";
				};
			};
		};
	};
}


