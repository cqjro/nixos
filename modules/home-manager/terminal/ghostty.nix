{pkgs, lib, config, inputs, ...}:
{
  programs.ghostty = {
    enable = true;
    settings = {
      # theme = "Banana Blueberry";
    };
  };
}
