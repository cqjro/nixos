{ ... }:
{
	# Secret Service provider for anything that stores credentials in the system
	# keyring: Electron's safeStorage (T3 Code's saved connections, Xodus Nexus'
	# Microsoft sign-in), gh, etc. Hyprland is launched by greetd on the desktop
	# hosts, so the login keyring is unlocked from the greetd PAM session as well
	# as from login. The unlock only happens at a password login, and only if the
	# keyring's password matches the login password.
	flake.modules.nixos.keyring = { ... }: {
		services.gnome.gnome-keyring.enable = true;
		# Keep the existing OpenSSH agent (modules/essentials/ssh.nix); GNOME's
		# gcr-ssh-agent would otherwise conflict with it.
		services.gnome.gcr-ssh-agent.enable = false;
		security.pam.services.greetd.enableGnomeKeyring = true;
	};

	flake.modules.homeManager.keyring = { ... }: {
		services.gnome-keyring.enable = true;
	};
}
