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

  # The home.packages option allows you to install Nix packages into your
  # environment.

  imports = [
    ../../modules/home-manager/desktop/hyprland.nix
    ../../modules/home-manager/desktop/waybar.nix
    ../../modules/home-manager/desktop/dunst.nix
    ../../modules/home-manager/xremap.nix
    ../../modules/home-manager/terminal/ghostty.nix
    ../../modules/home-manager/desktop/rofi.nix
    # ../../modules/nixos/stylix.nix
  ];

  # move this to a sepreate file later
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "eza -l --header";
      llt = "eza -l --tree --header";
      cd = "z";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # move this to a seperate file later
  programs.git = {
    enable = true;
    userName  = "cqjro";
    userEmail = "cairo.cristante@gmail.com";
  };

  home.packages = with pkgs; [
    # editors
    neovim
    vscode

    #cli tools
    neofetch # displays setup specs
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

    # terminals
    ghostty 

    # main apps
    discord
    vesktop # alternative discord client
    inputs.zen-browser.packages."${system}".default # zen-browser (change when package added to nix packages)
    obsidian
    spotify
    obs-studio

    # other
    font-awesome # used for waybar and other icons ?

  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {

    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/root/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
