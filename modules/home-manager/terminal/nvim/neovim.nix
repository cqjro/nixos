{pkgs, lib, config, inputs, ...}:
{
	programs.neovim = 
		let
			toLua = str: "lua << EOF\n${str}\nEOF\n";
			toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
			fakeVimPlugin = pkgs.runCommand "fakeVimPlugin" {} "mkdir $out";
		in
			{
			enable = true;

			defaultEditor = true;
			viAlias = true;
			vimAlias = true;
			vimdiffAlias = true;

			# packages required by neovim
			extraPackages = with pkgs; [
				# language servers, etc here
			];

			# extraLuaConfig = ''
				# ${builtins.readFile ./options.lua}
			# '';

			plugins = with pkgs.vimPlugins; [ 

				# Fake Vim Plugin - to load options before other plugins?
        { plugin = fakeVimPlugin; config = toLuaFile ./options.lua; }

				# LSP - Language Server Protocol
				{
					plugin = nvim-lspconfig;
					# config = toLuaFile ./plugins/lsp.lua
				}

				# Cmp - Completion
				{
					plugin = nvim-cmp;
					# config = toLuaFile ./plugins/cmp.lua
				}

				# Tree Sitter
				{
					plugin = (nvim-treesitter.withPlugins (p: [
						p.tree-sitter-nix
						p.tree-sitter-vim
						p.tree-sitter-markdown
						p.tree-sitter-markdown_inline
						p.tree-sitter-bash
						p.tree-sitter-lua
						p.tree-sitter-python
						p.tree-sitter-json
						p.tree-sitter-rust
						p.tree-sitter-javascript
						p.tree-sitter-typescript
					]));
					config = toLuaFile ./plugins/treesitter.lua;
				}

				# Comment Nvim
				{
					plugin = comment-nvim;
					config = toLua "require(\"Comment\").setup()";
				}

				# Telescope
				{
					plugin = telescope-nvim;
					config = toLuaFile ./plugins/telescope.lua;
				}
				telescope-fzf-native-nvim

				# Harpoon
				{
					plugin = harpoon2;
					config = toLuaFile ./plugins/harpoon.lua;
				}

				# Undotree
				{
					plugin = undotree;
					config = toLuaFile ./plugins/undotree.lua;
				}

				# Obsidian
				{
					plugin = obsidian-nvim;
					# config = toLuaFile ./plugins/obsidian.lua
				}
			];
		};
}
