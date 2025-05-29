{pkgs, lib, config, inputs, ...}:
{
  programs.neovim = 
  let
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
  in
  {
    enable = true;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraLuaConfig = ''
      ${builtins.readFile ./options.lua}
    '';

    plugins = with pkgs.vimPlugins; [
      {
        plugin = nvim-lspconfig;
	# config = toLuaFile ./plugins/lsp.lua
      }

      {
        plugin = nvim-cmp;
	# config = toLuaFile ./plugins/cmp.lua
      }

      {
        plugin = (nvim-treesitter.withPlugins (p: [
	  # p.tree-sitter-help
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

      {
        plugin = comment-nvim;
	config = toLua "require(\"Comment\").setup()";
      }

      {
        plugin = telescope-nvim;
	config = toLuaFile ./plugins/telescope.lua;
      }

      {
        plugin = harpoon2;
	config = toLuaFile ./plugins/harpoon.lua;
      }

      {
        plugin = undotree;
	config = toLuaFile ./plugins/undotree.lua;
      }
    ];
  };
}
