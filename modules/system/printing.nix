{ ... }:
{
	flake.modules.nixos.printing = {
		# Enable CUPS to print documents.
		services.printing.enable = true;
	};
}