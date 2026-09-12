{ inputs, ... }:
{
	flake.modules.homeManager."zen-browser" = { pkgs, config, lib, ... }: {
		imports = [ inputs.zen-browser.homeModules.twilight ];

		options.zenWebStyling = {
			siteStyles = lib.mkOption {
				type = lib.types.attrsOf lib.types.lines;
				default = {};
				description = "Per-domain CSS appended to userContent.css, wrapped in @-moz-document domain(<key>).";
};
		};

		config = {
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
						position = 2000;
						container = containers.Life.id;
					};
					"Nix" = {
						id = "f026db84-f49d-462f-b9bb-4f84f9d713f7";
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
				in let
colors = config.lib.stylix.colors;
					withColors = colors;
					zenContent = with withColors; lib.concatStringsSep "" [
						"@media (prefers-color-scheme: dark) {\n"
						"  /* Common variables affecting all pages */\n"
						"  @-moz-document url-prefix(\"about:\") {\n"
						"    :root {\n"
						"      --in-content-page-color: #${base05-hex} !important;\n"
						"      --color-accent-primary: #${base0D-hex} !important;\n"
						"      --color-accent-primary-hover: #${base06-hex} !important;\n"
						"      --color-accent-primary-active: #${base06-hex} !important;\n"
						"      background-color: #${base00-hex} !important;\n"
						"      --in-content-page-background: #${base00-hex} !important;\n"
						"    }\n"
						"  }\n"
						"\n"
						"  /* Variables and styles specific to about:newtab and about:home */\n"
						"  @-moz-document url(\"about:newtab\"), url(\"about:home\") {\n"
						"    :root {\n"
						"      --newtab-background-color: #${base00-hex} !important;\n"
						"      --newtab-background-color-secondary: #${base02-hex} !important;\n"
						"      --newtab-element-hover-color: #${base02-hex} !important;\n"
						"      --newtab-text-primary-color: #${base05-hex} !important;\n"
						"      --newtab-wordmark-color: #${base05-hex} !important;\n"
						"      --newtab-primary-action-background: #${base0D-hex} !important;\n"
						"    }\n"
						"\n"
						"    .icon { color: #${base0D-hex} !important; }\n"
						"\n"
						"    .search-wrapper .logo-and-wordmark .logo {\n"
						"      display: inline-block !important;\n"
						"      height: 82px !important;\n"
						"      width: 82px !important;\n"
						"      background-size: 82px !important;\n"
						"    }\n"
						"\n"
						"    @media (max-width: 609px) {\n"
						"      .search-wrapper .logo-and-wordmark .logo {\n"
						"        background-size: 64px !important;\n"
						"        height: 64px !important;\n"
						"        width: 64px !important;\n"
						"      }\n"
						"    }\n"
						"\n"
						"    .card-outer:is(:hover, :focus, .active):not(.placeholder) .card-title { color: #${base0D-hex} !important; }\n"
						"    .top-site-outer .search-topsite { background-color: #${base0D-hex} !important; }\n"
						"    .compact-cards .card-outer .card-context .card-context-icon.icon-download { fill: #${base0B-hex} !important; }\n"
						"  }\n"
						"\n"
						"  /* Variables and styles specific to about:preferences */\n"
						"  @-moz-document url-prefix(\"about:preferences\") {\n"
						"    :root {\n"
						"      --zen-colors-tertiary: #${base01-hex} !important;\n"
						"      --in-content-text-color: #${base05-hex} !important;\n"
						"      --link-color: #${base0D-hex} !important;\n"
						"      --link-color-hover: #${base06-hex} !important;\n"
						"      --zen-colors-primary: #${base02-hex} !important;\n"
						"      --in-content-box-background: #${base02-hex} !important;\n"
						"      --zen-primary-color: #${base0D-hex} !important;\n"
						"    }\n"
						"\n"
						"    groupbox, moz-card { background: #${base00-hex} !important; }\n"
						"    button, groupbox menulist { background: #${base02-hex} !important; color: #${base05-hex} !important; }\n"
						"    .main-content { background-color: #${base01-hex} !important; }\n"
						"\n"
						"    .identity-color-blue { --identity-tab-color: #${base0D-hex} !important; --identity-icon-color: #${base0D-hex} !important; }\n"
						"    .identity-color-turquoise { --identity-tab-color: #${base0C-hex} !important; --identity-icon-color: #${base0C-hex} !important; }\n"
						"    .identity-color-green { --identity-tab-color: #${base0B-hex} !important; --identity-icon-color: #${base0B-hex} !important; }\n"
						"    .identity-color-yellow { --identity-tab-color: #${base0A-hex} !important; --identity-icon-color: #${base0A-hex} !important; }\n"
						"    .identity-color-orange { --identity-tab-color: #${base09-hex} !important; --identity-icon-color: #${base09-hex} !important; }\n"
						"    .identity-color-red { --identity-tab-color: #${base08-hex} !important; --identity-icon-color: #${base08-hex} !important; }\n"
						"    .identity-color-pink { --identity-tab-color: #${base0E-hex} !important; --identity-icon-color: #${base0E-hex} !important; }\n"
						"    .identity-color-purple { --identity-tab-color: #${base0F-hex} !important; --identity-icon-color: #${base0F-hex} !important; }\n"
						"  }\n"
						"\n"
						"  /* Variables and styles specific to about:addons */\n"
						"  @-moz-document url-prefix(\"about:addons\") {\n"
						"    :root {\n"
						"      --zen-dark-color-mix-base: #${base01-hex} !important;\n"
						"      --background-color-box: #${base00-hex} !important;\n"
						"    }\n"
						"  }\n"
						"\n"
						"  /* Variables and styles specific to about:protections */\n"
						"  @-moz-document url-prefix(\"about:protections\") {\n"
						"    :root {\n"
						"      --zen-primary-color: #${base00-hex} !important;\n"
						"      --social-color: #${base0E-hex} !important;\n"
						"      --coockie-color: #${base0C-hex} !important;\n"
						"      --fingerprinter-color: #${base0A-hex} !important;\n"
						"      --cryptominer-color: #${base0D-hex} !important;\n"
						"      --tracker-color: #${base0B-hex} !important;\n"
						"      --in-content-primary-button-background-hover: #${base02-hex} !important;\n"
						"      --in-content-primary-button-text-color-hover: #${base05-hex} !important;\n"
						"      --in-content-primary-button-background: #${base03-hex} !important;\n"
						"      --in-content-primary-button-text-color: #${base05-hex} !important;\n"
						"    }\n"
						"\n"
						"    .card { background-color: #${base02-hex} !important; }\n"
						"  }\n"
						"}\n"
					];
					webSites = lib.concatStringsSep "" (lib.mapAttrsToList
						(domain: css: "@-moz-document domain(\"${domain}\") {\n${css}}\n")
						config.zenWebStyling.siteStyles);
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
							stylus
					];

					settings = {
						"zen.view.use-single-toolbar" = false;
						"zen.view.window.scheme" = lib.mkForce 0;
						"ui.systemUsesDarkTheme" = lib.mkForce 1;
						"layout.css.prefers-color-scheme.content-override" = 1;
						"toolkit.legacyUserProfileCustomizations.stylesheets" = true;
					};

					userChrome = (import "${inputs.stylix}/modules/zen-browser/userChrome.nix") {
						colors = colors;
						opacityHex = lib.toHexString (builtins.ceil (config.stylix.opacity.applications * 255));
					};

					userContent = zenContent + webSites;
				};	
			};
		};

		stylix.targets.zen-browser = {
				profileNames = ["default"];
				enableCss = false;
			};
		};
	};
}