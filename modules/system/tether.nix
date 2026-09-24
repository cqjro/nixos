{ inputs, ... }:
{
	flake.modules.nixos.tether = { ... }: {
		imports = [ inputs.tether.nixosModules.default ];

		# bluetoothd defaults the adapter class to A/V Hands-Free (0x000408).
		# The tether-btclass@ unit (from the module above) re-applies it with
		# btmgmt after every bluetooth restart, but bluetoothd recomputes the
		# class over that write, so main.conf must carry it too.
		hardware.bluetooth.settings.General.Class = "0x000408";

		programs.tether = {
			enable = true;

			# clipboard sync + file transfer via the ios app (avahi + tcp/5134)
			wifi = {
				enable = true;
				openFirewall = true;
			};

			# messages (MAP), contacts (PBAP), notification mirroring (ANCS)
			bluetooth = {
				enable = true;
				adapters = [ "hci0" ];
			};

			# OTP browser/mail extensions are opt-in: add "firefox" (zen-browser)
			# or "chromium" (brave) to the extensions list to enable native-messaging.
			extensions = [];
		};
	};
}
