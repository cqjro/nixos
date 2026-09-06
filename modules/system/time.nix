{ ... }:
{
	flake.modules.nixos.time = {
		# Set your time zone.
		time.timeZone = "America/Toronto";
	};
}