{ pkgs, ... }:

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
    ../../modules/keyboard/default.nix
    ../../modules/desktop/default.nix
    ../../modules/terminal/default.nix
		../../modules/apps/default.nix
  ];

	home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "zen";
    TERMINAL = "ghostty";
		NIXOS_OZONE_WL = "1";
		ELECTRON_OZONE_PLATFORM_HINT = "wayland";
		OZONE_PLATFORM_HINT = "wayland";
		XDG_SESSION_TYPE = "wayland";
		XDG_SESSION_DESKTOP = "Hyprland";
  };

	# get rid of mismatch version error on rebuild	
  stylix.enableReleaseChecks = false;

  # home.packages = with pkgs; [
		# # languages & frameworks
		# # # typescript
		# # go
		# # # flutter
		# #
		# # # latex/documents
		# # texlive.combined.scheme-full
		# # typst
  #
  #   # cli tools
  #   # nitch # config stats/neofetch replacement
  #   # btop # activity monitor
  #   # git
  #   # zsh # shell
  #   # ffmpeg
  #   # bat # displays file content with syntax highlighting
  #   # yazi # fast file manager
  #   # fzf # fuzzy text search
  #   # zoxide # smarter cd command
  #   # eza # better ls
  #   # dust # disk use analyzer
  #   # dua # interative disk use analyzer
  #   # ncspot # terminal spotify client (uses less ram)
  #   # starship # shell prompt (supports multiple shells)
		# # delta # better syntax highlighting for git diff
		# # jq # json command line processor
		# # pstree
		# # unzip # unzipping zip files from terminal
  #
  #   # terminals
  #   # ghostty 
  #
  #   # apps
		# # vlc
  # #   obsidian
  # #   spotify
  # #   obs-studio
		# # firefox # backup browser
		# # protonmail-desktop
		# # protonvpn-cli
		# # protonvpn-gui
  # #   zathura # pdf viewer
		# # sioyek # pdf viewer for academic documents
		# # localsend	
  # ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {	

  };

	home.sessionPath = [ 
		"/homes/cairo/.nixos"
	];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
