{ lib, ... }:
{
	flake.modules.nixos.manifest = {
		options.manifest.enableMillennium = lib.mkOption {
			type = lib.types.bool;
			default = true;
			description = ''
				Use millennium-steam (themed Steam client) instead of the vanilla steam package.
				Set to false for an untouched client.
			'';
		};

		options.manifest.enableSpicetify = lib.mkOption {
			type = lib.types.bool;
			default = true;
			description = ''
				Use the spicetify-patched Spotify client instead of a vanilla spotify install.
				Set to false for an untouched client.
			'';
		};
	};
}