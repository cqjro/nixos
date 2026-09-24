{ inputs, ... }:
{
	flake.modules.nixos.tether = { ... }: {
		imports = [ inputs.tether.nixosModules.default ];

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
