{inputs, pkgs, lib, ...}:
{
  imports = [
    inputs.xremap-flake.homeManagerModules.default
  ];
  services.xremap = {
    withHypr = true;
    config = {
      keymap = {
        name = "Remap Caps as Hyper/Escape";
        remap = {
          capslock = {
	    # held = "hyper"; # change to actual hyper key
	    alone = "esc";
	    alone_timeout_millis = 150;
	  };
	};
      };
    };
  };
}
