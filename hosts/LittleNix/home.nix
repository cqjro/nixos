{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cairo";
  home.homeDirectory = "/home/cairo";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  #TODO group these togeher with default import files like in example configs
  imports = [
    ../../modules/home-manager/desktop/hyprland.nix
    ../../modules/home-manager/desktop/waybar.nix
    ../../modules/home-manager/desktop/dunst.nix
    ../../modules/home-manager/desktop/xdg-desktop-entries.nix
    ../../modules/home-manager/xremap.nix
    ../../modules/home-manager/terminal/ghostty.nix
    ../../modules/home-manager/desktop/rofi.nix
    ../../modules/home-manager/terminal/btop.nix
    ../../modules/home-manager/terminal/yazi.nix
    ../../modules/home-manager/terminal/starship.nix
    ../../modules/home-manager/terminal/nvim/neovim.nix
    ../../modules/home-manager/terminal/bat.nix
    ../../modules/home-manager/terminal/zsh.nix
    ../../modules/home-manager/terminal/zoxide.nix
    ../../modules/home-manager/terminal/git.nix
    ../../modules/home-manager/terminal/ncspot.nix
		../../modules/home-manager/apps/discord/nixcord.nix
  ];

	home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "zen";
    TERMINAL = "ghostty";
		NIXOS_OZONE_WL = "1";
		ELECTRON_OZONE_PLATFORM_HINT = "wayland";
		OZONE_PLATFORM_HINT = "wayland";
  };

	# get rid of mismatch version error on rebuild	
  stylix.enableReleaseChecks = false;

  home.packages = with pkgs; [
    # editors
    # neovim
    vscode

    #cli tools
    neofetch # displays setup specs
    nitch # display setup specs
    btop # activity monitor
    git
    zsh # shell
    ffmpeg
    bat # displays file content with syntax highlighting
    yazi # fast file manager
    fzf # fuzzy text search
    zoxide # smarter cd command
    eza # better ls
    dust # disk use analyzer
    dua # interative disk use analyzer
    fselect # use sql queries to look for files
    ncspot # terminal spotify client (uses less ram)
    zathura # pdf viewer
    starship # shell prompt (supports multiple shells)
		delta # better syntax highlighting for git diff

    # terminals
    ghostty 

    # main apps
    inputs.zen-browser.packages."${system}".default # zen-browser (change when package added to nix packages)
    obsidian
    spotify
    obs-studio

    # other
    font-awesome # used for waybar and other icons maybe?

  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {	

  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
