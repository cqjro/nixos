{ ... }:
{
	# Shared MCP servers (programs.mcp.servers). Consumers opt in with their own
	# enableMcpIntegration, e.g. programs.claude-code in claude-code.nix.
	flake.modules.homeManager."mcp-servers" = { pkgs, ... }: {
		programs.mcp = {
			enable = true;
			servers = {
				# real NixOS / Home Manager / nixpkgs data (packages, options,
				# versions) so agents stop guessing attribute names
				nixos = {
					command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
				};
			};
		};
	};
}
