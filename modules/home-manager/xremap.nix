{inputs, pkgs, lib, ...}:
{
  services.xremap = {
    withHypr = true;
    config = {
      keymap = {
        name = "Remap Caps as Hyper/Escape";
        remap = {
          capslock = {
	    held = "hyper"; # if this doesn't work then do ctl + alt + shift + super
	    alone = "esc";
	    alone_timeout_millis = 150;
	  };
	};
      };
    };
  };
}
