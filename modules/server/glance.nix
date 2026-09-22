{ ... }:
{
	flake.modules.nixos.glance = { pkgs, lib, ... }:
	{
		# Dedicated user, mirroring the linkwarden/actual-budget modules. The
		# nixpkgs module uses DynamicUser=true by default; we pin it to a stable
		# user so the admin (and `sudo -u`) can manage /var/lib/glance and the
		# generated config is chowned to the same user (see the unit override).
		users.users.glance = {
			isSystemUser = true;
			group = "glance";
			home = "/var/lib/glance";
			createHome = true;
		};
		users.groups.glance = {};

		# When the stylix module is also enabled on the host,
		# services.glance.settings.theme is filled in from the base16 palette
		# (stylix target: glance).
		services.glance = {
			enable = true;
			# Values referenced as ${VAR} in settings (e.g. the auth password)
			# are read from this file at runtime, keeping secrets out of the
			# nix store. Lives outside the store, see the file permissions
			# steps in the README.
			environmentFile = "/var/lib/glance/glance.env";
			settings = {
				server = {
					host = "127.0.0.1"; # only reachable via cloudflared tunnel
					port = 8081; # free port, avoids homepage 8082 / linkwarden 8083
					proxied = true; # trust X-Forwarded-* from cloudflared for the login brute-force block
				};

				# Restrict dashboard access behind username/password login.
				# `auth.users` is a MAP keyed by username (not a list), and a
				# random `secret-key` from `glance secret:make` is mandatory.
				# Both secrets live in /var/lib/glance/glance.env.
				auth = {
					secret-key = "\${GLANCE_SECRET_KEY}";
					users = {
						admin = {
							password = "\${GLANCE_PASSWORD}";
						};
					};
				};

				pages = [
					{
						# Default "Home" page, as shipped in the glance docs.
						name = "Home";
						columns = [
							{
								size = "small";
								widgets = [
									{
										type = "calendar";
										"first-day-of-week" = "monday";
									}

									{
										type = "weather";
										location = "Vaughan, Ontario, Canada";
										units = "metric";
										"hour-format" = "12h";
									}

									{
										type = "rss";
										limit = 10;
										"collapse-after" = 3;
										cache = "12h";
										feeds = [
											{ url = "https://selfh.st/rss/"; title = "selfh.st"; limit = 4; }
											{ url = "https://ciechanow.ski/atom.xml"; }
											{ url = "https://www.joshwcomeau.com/rss.xml"; title = "Josh Comeau"; }
											{ url = "https://samwho.dev/rss.xml"; }
											{ url = "https://ishadeed.com/feed.xml"; title = "Ahmad Shadeed"; }
										];
									}
								];
							}
							{
								size = "full";
								widgets = [
									{
										type = "group";
										widgets = [
											{ type = "hacker-news"; }
											{ type = "lobsters"; }
										];
									}

									{
										type = "videos";
										channels = [
											"UCXuqSBlHAE6Xw-yeJA0Tunw" # Linus Tech Tips
											"UCR-DXc1voovS8nhAvccRZhg" # Jeff Geerling
											"UCsBjURrPoezykLs9EqgamOA" # Fireship
											"UCBJycsmduvYEL83R_U4JriQ" # Marques Brownlee
											"UCHnyfMqiRRG1u-2MsSQLbXA" # Veritasium
										];
									}

									{
										type = "group";
										widgets = [
											{ type = "reddit"; subreddit = "technology"; "show-thumbnails" = true; }
											{ type = "reddit"; subreddit = "selfhosted"; "show-thumbnails" = true; }
										];
									}
								];
							}
							{
								size = "small";
								widgets = [
									{
										type = "markets";
										markets = [
											{ symbol = "SPY"; name = "S&P 500"; }
											{ symbol = "BTC-USD"; name = "Bitcoin"; }
											{ symbol = "NVDA"; name = "NVIDIA"; }
											{ symbol = "AAPL"; name = "Apple"; }
											{ symbol = "MSFT"; name = "Microsoft"; }
										];
									}

									{
										type = "releases";
										cache = "1d";
										# Without a read-only Github token the API allows
										# 60 requests/hour.
										repositories = [
											"glanceapp/glance"
											"go-gitea/gitea"
											"immich-app/immich"
											"syncthing/syncthing"
										];
									}
								];
							}
						];
					}

					{
						# Default "Markets" page, as shipped in the glance docs.
						name = "Markets";
						columns = [
							{
								size = "small";
								widgets = [
									{
										type = "markets";
										title = "Indices";
										markets = [
											{ symbol = "SPY"; name = "S&P 500"; }
											{ symbol = "DX-Y.NYB"; name = "Dollar Index"; }
										];
									}

									{
										type = "markets";
										title = "Crypto";
										markets = [
											{ symbol = "BTC-USD"; name = "Bitcoin"; }
											{ symbol = "ETH-USD"; name = "Ethereum"; }
										];
									}

									{
										type = "markets";
										title = "Stocks";
										"sort-by" = "absolute-change";
										markets = [
											{ symbol = "NVDA"; name = "NVIDIA"; }
											{ symbol = "AAPL"; name = "Apple"; }
											{ symbol = "MSFT"; name = "Microsoft"; }
											{ symbol = "GOOGL"; name = "Google"; }
											{ symbol = "AMD"; name = "AMD"; }
											{ symbol = "RDDT"; name = "Reddit"; }
											{ symbol = "AMZN"; name = "Amazon"; }
											{ symbol = "TSLA"; name = "Tesla"; }
											{ symbol = "INTC"; name = "Intel"; }
											{ symbol = "META"; name = "Meta"; }
										];
									}
								];
							}
							{
								size = "full";
								widgets = [
									{
										type = "rss";
										title = "News";
										style = "horizontal-cards";
										feeds = [
											{ url = "https://feeds.bloomberg.com/markets/news.rss"; title = "Bloomberg"; }
											{ url = "https://moxie.foxbusiness.com/google-publisher/markets.xml"; title = "Fox Business"; }
											{ url = "https://moxie.foxbusiness.com/google-publisher/technology.xml"; title = "Fox Business"; }
										];
									}

									{
										type = "group";
										widgets = [
											{ type = "reddit"; "show-thumbnails" = true; subreddit = "technology"; }
											{ type = "reddit"; "show-thumbnails" = true; subreddit = "wallstreetbets"; }
										];
									}

									{
										type = "videos";
										style = "grid-cards";
										"collapse-after-rows" = 3;
										channels = [
											"UCvSXMi2LebwJEM1s4bz5IBA" # New Money
											"UCV6KDgJskWaEckne5aPA0aQ" # Graham Stephan
											"UCAzhpt9DmG6PnHXjmJTvRGQ" # Federal Reserve
										];
									}
								];
							}
							{
								size = "small";
								widgets = [
									{
										type = "rss";
										title = "News";
										limit = 30;
										"collapse-after" = 13;
										feeds = [
											{ url = "https://www.ft.com/technology?format=rss"; title = "Financial Times"; }
											{ url = "https://feeds.a.dj.com/rss/RSSMarketsMain.xml"; title = "Wall Street Journal"; }
										];
									}
								];
							}
						];
					}

					{
						# Default "Gaming" page, as shipped in the glance docs.
						name = "Gaming";
						columns = [
							{
								size = "small";
								widgets = [
									{
										type = "twitch-top-games";
										limit = 20;
										"collapse-after" = 13;
										exclude = [
											"just-chatting"
											"pools-hot-tubs-and-beaches"
											"music"
											"art"
											"asmr"
										];
									}
								];
							}
							{
								size = "full";
								widgets = [
									{
										type = "group";
										widgets = [
											{ type = "reddit"; "show-thumbnails" = true; subreddit = "pcgaming"; }
											{ type = "reddit"; subreddit = "games"; }
										];
									}

									{
										type = "videos";
										style = "grid-cards";
										"collapse-after-rows" = 3;
										channels = [
											"UCNvzD7Z-g64bPXxGzaQaa4g" # gameranx
											"UCZ7AeeVbyslLM_8-nVy2B8Q" # Skill Up
											"UCHDxYLv8iovIbhrfl16CNyg" # GameLinked
											"UC9PBzalIcEQCsiIkq36PyUA" # Digital Foundry
										];
									}
								];
							}
							{
								size = "small";
								widgets = [
									{
										type = "reddit";
										subreddit = "gamingnews";
										limit = 7;
										style = "vertical-cards";
									}
								];
							}
						];
					}

					{
						# Startpage-style dashboard (see the glance repo's
						# preconfigured pages): search + live service status
						# (monitor) + the bookmarks list.
						# Slim, started page in the docs. `hide-desktop-navigation`
						# is omitted: we have multiple pages now, so the page switcher
						# must stay visible.
						name = "Homelab";
						width = "slim";
						"center-vertically" = true;
						columns = [
							{
								size = "full";
								widgets = [
									{
										type = "search";
										autofocus = true;
									}

									{
										# Reachability of each app through its cloudflared
										# tunnel; redirects (login pages) still count as
										# online via alt-status-codes.
										type = "monitor";
										cache = "1m";
										title = "Services";
										sites = [
											{
												title = "Paperless";
												url = "https://docs.cqjro.ca";
												icon = "si:paperlessngx";
												alt-status-codes = [ 200 201 301 302 303 307 308 ];
											}
											{
												title = "Beszel";
												url = "https://status.cqjro.ca";
												alt-status-codes = [ 200 201 301 302 303 307 308 ];
											}
											{
												title = "Linkwarden";
												url = "https://link.cqjro.ca";
												alt-status-codes = [ 200 201 301 302 303 307 308 ];
											}
											{
												title = "Actual Budget";
												url = "https://budget.cqjro.ca";
												icon = "si:actualbudget";
												alt-status-codes = [ 200 201 301 302 303 307 308 ];
											}
											{
												title = "Glance";
												url = "https://home.cqjro.ca";
												icon = "si:glance";
												alt-status-codes = [ 200 201 301 302 303 307 308 ];
											}
										];
									}

									{
										# v0.8: `group` tabs OTHER widgets — the widget for a
										# list of links is `bookmarks` (groups -> links).
										type = "bookmarks";
										groups = [
											{
												title = "Services";
												links = [
													{ title = "Paperless"; url = "https://docs.cqjro.ca"; }
													{ title = "Beszel"; url = "https://status.cqjro.ca"; }
													{ title = "Linkwarden"; url = "https://link.cqjro.ca"; }
													{ title = "Actual Budget"; url = "https://budget.cqjro.ca"; }
													{ title = "NixOS Config"; url = "https://github.com/cqjro/nixos"; }
												];
											}
										];
									}
								];
							}
						];
					}
				];
			};
		};

		# Pin glance to its dedicated user instead of a dynamic user.
		# `StateDirectory = glance` (/var/lib/glance) then gets chowned to
		# `glance` on unit start, and the ExecStartPre chown keeps the generated
		# config in line with the same user.
		systemd.services.glance.serviceConfig = {
			DynamicUser = lib.mkForce false;
			User = "glance";
			Group = "glance";
		};

		services.cloudflared = {
			tunnels."cc6ff7b2-85db-4d20-a99d-8ac3d05d14f7" = {
				# TODO: replace with your tunnel UUID (cloudflared tunnel create glance)
				credentialsFile = "/var/lib/cloudflared/glance.json";
				default = "http_status:404";
				ingress = {
					"home.cqjro.ca" = "http://localhost:8081";
				};
			};
		};
	};
}
