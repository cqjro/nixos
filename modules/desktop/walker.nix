{inputs, config, ...}:
{

imports = [
	inputs.walker.homeManagerModules.default
];

	programs.walker = {
		enable = true;
		themes."mytheme".style = ''
    window {
      background-color: transparent;
    }

    #window {
      background-color: #${config.lib.stylix.colors.base00};
      /* border-radius: 12px; */
      border: 1px solid #${config.lib.stylix.colors.base03};
    }

    #input {
      color: #${config.lib.stylix.colors.base05};
      background-color: #${config.lib.stylix.colors.base01};
    }

    #typeahead {
      color: #${config.lib.stylix.colors.base03};
    }
  '';
	};
}
