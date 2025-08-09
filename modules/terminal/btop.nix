{pkgs, ...}:
{
	home.packages = with pkgs; [
		btop
	];
  programs.btop = {
    enable = true;
    settings = {
      update_ms = 100;
    };
  };
}
