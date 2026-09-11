{ ... }:
{
	flake.modules.homeManager."nvim" = { pkgs, config, lib, ... }: {
# home.packages = with pkgs; [
# 	neovim
# ];

home.file."${config.xdg.configHome}/nvim/queries/nix/injections.scm".source = 
  ./injections.scm;

	programs.neovim = 
		let
		toLua = str: str;
	toLuaFile = file: builtins.readFile file;
	fakeVimPlugin = pkgs.runCommand "fakeVimPlugin" {} "mkdir $out";
	in
	{
		enable = true;
		defaultEditor = true;
		viAlias = true;
		vimAlias = true;
		vimdiffAlias = true;

		withRuby = false;
		withPython3 = true;

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
				tinymist # typst lsp

# other program dependencies
				imagemagick
				ghostscript
				mermaid-cli
				textidote # supposed to add grammar/spell check to latex but not working
				pstree # needed for lsp's?
# xdotool # for zathura switch on latex complie
				websocat # typst-preview dependency 
		];

		extraLuaPackages = ps: [ 
			ps.magick
		];

# place lines into this function such that it gets called after everything to avoid race conditions
		initLua = let
			stylixEnabled = config ? stylix && config.stylix.enable;
			themify = let
				wh = config.lib.stylix.colors.withHashtag;
			in ''
				local ok, _ = pcall(vim.cmd.colorscheme, 'minischeme')
				if ok then
					require('mini.base16').setup({
						palette = {
							base00 = '${wh.base00}', base01 = '${wh.base01}', base02 = '${wh.base02}', base03 = '${wh.base03}',
							base04 = '${wh.base04}', base05 = '${wh.base05}', base06 = '${wh.base06}', base07 = '${wh.base07}',
							base08 = '${wh.base08}', base09 = '${wh.base09}', base0A = '${wh.base0A}', base0B = '${wh.base0B}',
							base0C = '${wh.base0C}', base0D = '${wh.base0D}', base0E = '${wh.base0E}', base0F = '${wh.base0F}'
						}
					})
				end
				vim.api.nvim_set_hl(0, "NormalFloat", { fg = '${wh.base05}', bg = "NONE" })
			'';
		in ''
			vim.defer_fn(function()
				${lib.optionalString stylixEnabled themify}
			end, 0)
			'';

		plugins = with pkgs.vimPlugins; [ 

# Fake Vim Plugin - to load options before other plugins?
# https://discourse.nixos.org/t/specify-the-order-in-which-lua-files-are-evaluated-when-configuring-neovim/48113
		{
			plugin = fakeVimPlugin; 
			config = toLuaFile ./options.lua;
			type = "lua";
		}

		{
			plugin = nvim-lspconfig;
			config = toLuaFile ./plugins/lsp.lua;
			type = "lua";
		}

		{
			plugin = nvim-cmp;
			config = toLuaFile ./plugins/cmp.lua;
			type = "lua";
		}
		cmp-nvim-lsp


		{
			plugin = luasnip;
			config = toLuaFile ./plugins/luasnip.lua;
			type = "lua";
		}

		{
			plugin = nvim-treesitter.withAllGrammars;
			config = toLuaFile ./plugins/treesitter.lua;
			type = "lua";
		}

		{
			plugin = comment-nvim;
			config = toLua "require(\"Comment\").setup()";
			type = "lua";
		}

		{
			plugin = telescope-nvim;
			config = toLuaFile ./plugins/telescope.lua;
			type = "lua";
		}	

		telescope-fzf-native-nvim

		{ 
			plugin = harpoon2;
			config = toLuaFile ./plugins/harpoon.lua;
			type = "lua";
		}

		{ 
			plugin = undotree;
			config = toLuaFile ./plugins/undotree.lua;
			type = "lua";
		}

# {
# 	plugin = obsidian-nvim;
# 	config = toLuaFile ./plugins/obsidian.lua;
# }
# plenary-nvim # just incase because obsidian-nvim has this as a required dependency

		{
			plugin = lualine-nvim;
			config = toLuaFile ./plugins/lualine.lua;
			type = "lua";
		}

		{
			plugin = nvim-highlight-colors;
			config = toLua "require(\"nvim-highlight-colors\").setup()"; # maybe make a file later if more setup needed
			type = "lua";
		}	

		{
			plugin = noice-nvim;
			config = toLuaFile ./plugins/noice.lua;
			type = "lua";
		}

		{
			plugin = nvim-notify;
			config = toLuaFile ./plugins/nvim-notify.lua;
			type = "lua";
		}

		{
			plugin = trouble-nvim;
			config = toLuaFile ./plugins/trouble.lua;
			type = "lua";
		}

		{
			plugin = img-clip-nvim;
			config = toLuaFile ./plugins/img-clip.lua;
			type = "lua";
		}

		{
			plugin = snacks-nvim;
			config = toLuaFile ./plugins/snacks.lua;
			type = "lua";
		}

		{
			plugin = vimtex;
			config = toLuaFile ./plugins/vimtex.lua;
			type = "lua";
		}

		{
			plugin = typst-preview-nvim;
			config = toLuaFile ./plugins/typst-preview.lua;
			type = "lua";
		}

		];
	};
	};
}
