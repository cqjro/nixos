{pkgs, ...}:
{
	programs.neovide = {
		enable = true;
	};

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
				lua-language-server
				pyright
				nixd
				rust-analyzer
				gopls
				texlab
				typescript-language-server
			
				# other program dependencies
				imagemagick
				ghostscript
				mermaid-cli
				# xdotool # for zathura switch on latex complie	
			];

			extraLuaPackages = ps: [ 
				ps.magick
			];

			# place lines into this function such that it gets called after everything to avoid race conditions
			extraLuaConfig = ''
				vim.defer_fn(function()
					vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#b8b0c6", bg = "NONE" })
				end, 0)
			'';
			
			plugins = with pkgs.vimPlugins; [ 

				# Fake Vim Plugin - to load options before other plugins?
				# https://discourse.nixos.org/t/specify-the-order-in-which-lua-files-are-evaluated-when-configuring-neovim/48113
				{
					plugin = fakeVimPlugin; 
					config = toLuaFile ./options.lua; 
				}

				{
					plugin = nvim-lspconfig;
					config = toLuaFile ./plugins/lsp.lua;
				}

				{
					plugin = nvim-cmp;
					config = toLuaFile ./plugins/cmp.lua;
				}
				cmp-nvim-lsp


				{
					plugin = luasnip;
					config = toLuaFile ./plugins/luasnip.lua;
				}

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
						p.tree-sitter-go
						p.tree-sitter-latex
						p.tree-sitter-typst
						p.tree-sitter-bash
						p.tree-sitter-regex
						p.tree-sitter-css
						p.tree-sitter-html
						p.tree-sitter-norg
						p.tree-sitter-scss
						p.tree-sitter-svelte
						p.tree-sitter-tsx
						p.tree-sitter-vue
					]));
					config = toLuaFile ./plugins/treesitter.lua;
				}

				{
					plugin = comment-nvim;
					config = toLua "require(\"Comment\").setup()";
				}

				{
					plugin = telescope-nvim;
					config = toLuaFile ./plugins/telescope.lua;
				}	

				telescope-fzf-native-nvim

				{ 
					plugin = harpoon2;
					config = toLuaFile ./plugins/harpoon.lua;
				}

				{ 
					plugin = undotree;
					config = toLuaFile ./plugins/undotree.lua;
				}

				{
					plugin = obsidian-nvim;
					config = toLuaFile ./plugins/obsidian.lua;
				}
				plenary-nvim # just incase because obsidian-nvim has this as a required dependency

				{
					plugin = lualine-nvim;
					config = toLuaFile ./plugins/lualine.lua;
				}

				{
					plugin = nvim-highlight-colors;
					config = toLua "require(\"nvim-highlight-colors\").setup()"; # maybe make a file later if more setup needed
				}	

				{
					plugin = noice-nvim;
					config = toLuaFile ./plugins/noice.lua;
				}

				{
					plugin = nvim-notify;
					config = toLuaFile ./plugins/nvim-notify.lua;
				}

				{
					plugin = trouble-nvim;
					config = toLuaFile ./plugins/trouble.lua;
				}
	
				{
					plugin = img-clip-nvim;
					config = toLuaFile ./plugins/img-clip.lua;
				}

				{
					plugin = snacks-nvim;
					config = toLuaFile ./plugins/snacks.lua;
				}

				{
					plugin = vimtex;
					config = toLuaFile ./plugins/vimtex.lua;
				}
	
			];
		};
}
