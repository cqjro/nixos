{ ... }:
{
	flake.modules.nixos.dbus = {
		services.dbus.enable = true;
	};
}