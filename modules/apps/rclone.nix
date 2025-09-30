{pkgs, config, ...}:
{
	home.packages = with pkgs; [
		rclone
		rclone-ui
		rclone-browser
	];

	programs.rclone = {
		enable = true;
		remotes = {
			protondrive = {
				config = {
					type = "protondrive";
					username = "mail@cqjro.ca";
				};
				secrets = {
					password = config.age.secrets.protondrive-password.path;
				};
			};
		};
	};

	# Define the secret
	# Define the agenix secret
	age.secrets.protondrive-password = {
		file = ./secrets/protondrive-password.age;
		owner = "your-username";
		mode = "0400";
	};
	# Your sync service (same as before)
	systemd.services.protondrive-sync = {
		description = "Sync files with ProtonDrive";
		after = [ "network-online.target" ];
		wants = [ "network-online.target" ];

		serviceConfig = {
			Type = "oneshot";
			User = "cairo";
			ExecStart = "${pkgs.rclone}/bin/rclone sync protondrive:/ /home/cairo/ProtonDrive/ --progress";
		};
	};

	systemd.timers.protondrive-sync = {
		description = "Timer for ProtonDrive sync";
		wantedBy = [ "timers.target" ];

		timerConfig = {
			OnBootSec = "15min";
			OnUnitActiveSec = "30min";
			Unit = "protondrive-sync.service";
		};
	};
}
}::
