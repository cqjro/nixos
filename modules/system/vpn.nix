{pkgs, inputs, ...}:
{
	environment.systemPackages = with pkgs; [
		inputs.openconnect-sso.packages.${pkgs.system}.openconnect-sso
	];

	# Create a custom openssl config file
	environment.etc."ssl/openssl_legacy.cnf".text = ''
		openssl_conf = openssl_init

		[openssl_init]
		ssl_conf = ssl_sect

		[ssl_sect]
		system_default = system_default_sect

		[system_default_sect]
		Options = UnsafeLegacyRenegotiation
	'';

	# Set the environment variable to use it
	environment.variables = {
		OPENSSL_CONF = "/etc/ssl/openssl_legacy.cnf";
	};
}

