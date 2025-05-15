{inputs, pkgs, lib, ...}:
{
  imports = [
    inputs.xremap-flake.homeManagerModules.default
  ];
  services.xremap = {
    withHypr = true;
    config = {
      modmap = [
        {
          name = "Remap Caps as Super/Escape";
          remap = {
            CapsLock = {
	      held = "Super_L"; # change to actual hyper key
	      alone = "esc";
	      alone_timeout_millis = 150;
	    };
	  };
	}
      ];
    };
  };
}

