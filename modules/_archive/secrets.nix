# Archived from modules/essentials/secrets.nix
#
# Why: sops-nix had a single consumer (Glance's login password and session key),
# and the owner decided on 2026-11-02 to keep secrets as on-host files for now.
# Revisit if a secret must be reproducible from git or keeping values out of the
# repo becomes unmanageable. The design, comparison and bootstrap steps are in
# docs/secrets.md section 5; read 5.7 first if the repo is public.
#
# Would sit at: modules/essentials/secrets.nix, with its creation-rules template
# (modules/_archive/secrets.sops.yaml) at the repo root as .sops.yaml.
#
# To reintegrate:
#   1. git mv modules/_archive/secrets.nix modules/essentials/secrets.nix
#      git mv modules/_archive/secrets.sops.yaml .sops.yaml
#   2. flake.nix: uncomment the `sops-nix` input, then `nix flake lock`.
#   3. modules/hosts/host.nix: add `inputs.self.modules.nixos.secrets` and
#      `inputs.self.modules.nixos."secrets-glance"` to REDRUM's list (after glance).
#   4. Bootstrap the age keys (docs/secrets.md 5.4), create secrets/REDRUM.yaml,
#      `./rebuild.sh build REDRUM`, then the human switches REDRUM.
#
{ inputs, ... }:
{
	# Encrypted secrets with sops-nix (docs/secrets.md has the why and the runbook).
	#
	# Inert until bootstrapped: the module only switches on when the host has an
	# encrypted file at secrets/<hostname>.yaml (tracked in git). Without it the
	# host evaluates and builds exactly as before, so agents and CI can build
	# without any key. Ciphertext in the repo is safe for agents to read; only the
	# host's SSH key (and the admin's age key) can decrypt it.
	flake.modules.nixos.secrets = { config, lib, ... }: {
		imports = [ inputs.sops-nix.nixosModules.sops ];

		options.secrets.file = lib.mkOption {
			type = lib.types.nullOr lib.types.path;
			default =
				let candidate = ../../secrets + "/${config.networking.hostName}.yaml";
				in if builtins.pathExists candidate then candidate else null;
			defaultText = "secrets/<hostname>.yaml when it exists, else null";
			description = "Encrypted sops file for this host; null leaves secrets management off.";
		};

		config = lib.mkIf (config.secrets.file != null) {
			sops = {
				defaultSopsFile = config.secrets.file;
				# the host's ed25519 SSH key is the decryption identity (converted to
				# age at activation): it exists before the first switch and needs no
				# network or keyboard, so a headless boot decrypts unattended
				age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
				# never fall back to GPG or a generated key
				gnupg.sshKeyPaths = [ ];
				age.generateKey = false;
			};
		};
	};

	# First consumer, REDRUM: Glance's login password and session key move from a
	# hand-written /var/lib/glance/glance.env to sops. The two keys below must exist
	# in secrets/REDRUM.yaml (docs/secrets.md, "Bootstrap"); until that file exists
	# this fragment does nothing and glance keeps reading the hand-written file.
	flake.modules.nixos."secrets-glance" = { config, lib, ... }: {
		config = lib.mkIf (config.secrets.file != null) {
			sops.secrets.glance_secret_key = { };
			sops.secrets.glance_password = { };

			# rendered under /run/secrets/rendered (tmpfs, root-only); systemd reads
			# EnvironmentFile as root, so glance's own user needs no access
			sops.templates."glance.env" = {
				content = ''
					GLANCE_SECRET_KEY=${config.sops.placeholder.glance_secret_key}
					GLANCE_PASSWORD=${config.sops.placeholder.glance_password}
				'';
				restartUnits = [ "glance.service" ];
			};

			services.glance.environmentFile = lib.mkForce config.sops.templates."glance.env".path;
		};
	};
}
