{ inputs, ... }:
{
	flake.modules.nixos.tether = { ... }: {
		imports = [ inputs.tether.nixosModules.default ];

		# TODO-remove: registry row 13. What tether's wifi.enable would do, in the
		# current avahi option names (publish-addresses is what the obsolete
		# publish.userServices maps to). wifi.enable stays off below: tether's
		# module sets the obsolete services.avahi.publish.{enable,userServices},
		# which warn on every eval.
		services.avahi = {
			enable = true;
			settings.publish = {
				disable-publishing = false;
				disable-user-service-publishing = false;
				publish-addresses = true;
			};
		};

		# bluetoothd defaults the adapter class to A/V Hands-Free (0x000408).
		# The tether-btclass@ unit (from the module above) re-applies it with
		# btmgmt after every bluetooth restart, but bluetoothd recomputes the
		# class over that write, so main.conf must carry it too.
		hardware.bluetooth.settings.General.Class = "0x000408";

		programs.tether = {
			enable = true;

			# clipboard sync + file transfer via the ios app (avahi + tcp/5134);
			# avahi itself is configured above
			wifi.openFirewall = true;

			# messages (MAP), contacts (PBAP), notification mirroring (ANCS)
			bluetooth = {
				enable = true;
				adapters = [ "hci0" ];
			};

			# OTP browser extensions are opt-in: "firefox" targets zen-browser via
			# native-messaging, "chromium" targets brave. Tether's upstream NixOS
			# module validates this against its own enum.
			extensions = [ "firefox" ];
		};
	};
}
