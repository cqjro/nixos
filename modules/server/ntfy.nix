{ ... }:
let
	# 8086 is the ABT sidecar, 8087 is reserved for audiobookshelf, 8088 is
	# t3code.nix.
	port = 8089;
in
{
	# OPTIONAL: not listed in modules/hosts/host.nix. Self-hosted ntfy for agent
	# notifications (docs/notifications.md). The zero-infrastructure alternative
	# is ntfy.sh with a private topic, which needs no module at all.
	#
	# Tailscale only, no Cloudflare tunnel: it binds loopback and the human
	# publishes it on the tailnet (agents must not run `tailscale serve`):
	#   sudo tailscale serve --bg --https=8443 http://127.0.0.1:8089
	# Then base-url below must equal https://redrum.<tailnet>.ts.net:8443.
	flake.modules.nixos.ntfy = { lib, ... }: {
		# services.ntfy-sh runs as its own static `ntfy-sh` user with
		# /var/lib/ntfy-sh, which satisfies the dedicated-user rule.
		services.ntfy-sh = {
			enable = true;
			settings = {
				listen-http = "127.0.0.1:${toString port}";
				# TODO: replace with the real tailnet name (never committed per-machine
				# values elsewhere; this one is only a placeholder)
				base-url = lib.mkDefault "https://redrum.example.ts.net:8443";
				# tailscale serve is the reverse proxy
				behind-proxy = true;
				cache-file = "/var/lib/ntfy-sh/cache.db";
				# deny by default: publish and subscribe need a user or token
				# (create with `sudo -u ntfy-sh ntfy user add` / `ntfy token add`)
				auth-file = "/var/lib/ntfy-sh/user.db";
				auth-default-access = "deny-all";
				# iOS cannot hold a socket open, so a self-hosted server needs
				# ntfy.sh to relay an empty "poll" ping to APNs. The message text
				# never leaves this machine; only a topic hash does.
				upstream-base-url = "https://ntfy.sh";
			};
		};
	};
}
