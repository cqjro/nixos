{ inputs, ... }: {
  imports = [ inputs.zen-browser.homeModules.twilight ];
  programs.zen-browser = {
    enable = true;
    # any other options under `programs.firefox` are also supported here.
    # see `man home-configuration.nix`.


  };
}
