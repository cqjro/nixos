{pkgs, lib, config, inputs, ...}:
{
  programs.btop = {
    enable = true;
    settings = {
      update_ms = 100;
    };
  };
}
