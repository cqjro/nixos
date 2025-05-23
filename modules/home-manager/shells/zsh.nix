{ pkgs, lib, config, ... }: {
  options = {
    zsh.enable = 
      lib.mkEnableOption "enable zsh";
  };

  config = lib.mkIf config.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      sytanxHighlighting.enable = true;

      shellAliases = {
        ll = "ls -l";
      };
    };
  };
}
