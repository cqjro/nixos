{ inputs, ... }:
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
					# TODO-remove: upstream flake instead of pkgs.mcp-nixos, which fails
					# to build (fastmcp-slim/mcp version skew in nixpkgs). Once
					# `nix build nixpkgs#mcp-nixos` works: command = "${pkgs.mcp-nixos}/bin/mcp-nixos"
					# and delete the flake input.
					command = "${inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/mcp-nixos";
				};
			};
		};
	};
}
