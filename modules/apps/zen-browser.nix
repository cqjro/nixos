{ inputs, pkgs, ... }:
{
	imports = [ inputs.zen-browser.homeModules.twilight ];
	programs.zen-browser = {
		enable = true;
		policies = {
			AutofilledAddressEnabled = true;
			AutofilledCreditCardEnabled = false;
			DisableAppUpdate = true;
			DisableFeedbackCommands = true;
			DisableFirefoxStudies = true;
			DisablePocket = true;
			DisableTelemetry = true;
			NoDefaultBookmarks = true;
			OfferToSaveLogins = false;
			EnableTrackingProtection = {
				Value = true;
				Locked = true;
				Cryptomining = true;
				Fingerprinting = true;
			};

			# for browser extensions that are not packaged by rycee
			ExtensionSettings = {
				"myallychou@gmail.com" = {
      		install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/youtube-recommended-videos/latest.xpi";
      		installation_mode = "normal_installed";
    		};
			};
		};

		profiles = {
			"default" = let
				containers = {
					Work = {
						color = "blue";
						icon = "briefcase";
						id = 1;
					};
					Life = {
						color = "green";
						icon = "tree";
						id = 2;
					};
				};
			spaces = {
				"Browsing" = {
					id = "7653bf48-e638-47fe-be29-ce1e70cce6f7";
					icon = "🔍";
					position = 1000;
					container = containers.Life.id;
				};
				"Entertainment" = {
					id = "a6adea55-7eaf-4f65-8d93-93f8e42b552d";
					icon = "🎭";
					position = 1000;
					container = containers.Life.id;
				};
				"Nix" = {
					id = "2441acc9-79b1-4afb-b582-ee88ce554ec0";
					icon = "❄️";
					position = 3000;
				};
			};
			pins = {
			# Entertainment Workspace
				"Youtube" = {
					id = "2ebbc066-e21f-45f0-a55c-64b0f28736c8";
					workspace = spaces.Entertainment.id;
					url = "https://www.youtube.com/";
					position = 200;
				};
				"Reddit" = {
					id = "ccb383d6-fed6-4bde-be9a-3a582b4d9cb5";
					workspace = spaces.Entertainment.id;
					url = "https://www.reddit.com/";
					position = 201;
				};
				
				"Instagram" = {
					id = "6306288b-8033-48a8-90ea-8160cbae7d69";
					workspace = spaces.Entertainment.id;
					url = "https://www.instagram.com/";
					position = 202;
				};
			# Nix Workspace
				"Nix Packages" = {
					id = "f8dd784e-11d7-430a-8f57-7b05ecdb4c77";
					workspace = spaces.Nix.id;
					url = "https://search.nixos.org/packages";
					position = 200;
				};
				"Nix Options" = {
					id = "92931d60-fd40-4707-9512-a57b1a6a3919";
					workspace = spaces.Nix.id;
					url = "https://search.nixos.org/options";
					position = 201;
				};
				"Home Manager Options" = {
					id = "2eed5614-3896-41a1-9d0a-a3283985359b";
					workspace = spaces.Nix.id;
					url = "https://home-manager-options.extranix.com";
					position = 202;
				};
			};
			in {
				containersForce = true;
				pinsForce = true;
				spacesForce = true;
				inherit containers pins spaces;
				extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
					ublock-origin
						proton-pass
						darkreader
						return-youtube-dislikes
				];

				settings = {
					"zen.view.use-single-toolbar" = false;
				};
			};	
		};
	};

	stylix.targets.zen-browser.profileNames = ["default"];
}
