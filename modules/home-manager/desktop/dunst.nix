{pkgs, lib, config, inputs, ...}:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        follow = "mouse";
        indicate_hidden = "yes";
        offset = "10x10";
        notification_height = 0;
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        text_icon_padding = 0;
        frame_width = 2;
        frame_color = lib.mkForce "#${config.lib.stylix.colors.base05}";
        separator_color = lib.mkForce "frame";
        sort = "yes";
        idle_threshold = 120;
        # font = "monospace 10";
        line_height = 0;
        markup = "full";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        word_wrap = "yes";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = "yes";
        min_icon_size = 0;
        max_icon_size = 64;
        width = "500";
      # Not sure what this is used for but I don't have it set up
      # icon_path = /usr/share/icons/Papirus-Dark/16x16/status/:/usr/share/icons/Papirus-Dark/16x16/devices/:/usr/share/icons/Papirus-Dark/16x16/actions/:/usr/share/icons/Papirus-Dark/16x16/animations/:/usr/share/icons/Papirus-Dark/16x16/apps/:/usr/share/icons/Papirus-Dark/16x16/categories/:/usr/share/icons/Papirus-Dark/16x16/emblems/:/usr/share/icons/Papirus-Dark/16x16/emotes/:/usr/share/icons/Papirus-Dark/16x16/devices/mimetypes:/usr/share/icons/Papirus-Dark/16x16/panel/:/usr/share/icons/Papirus-Dark/16x16/places/
  
      # I don't have this setup either, change to rofi and zen-browser 
      # dmenu = /usr/bin/wofi -p dunst:
      # browser = /usr/bin/firefox --new-tab
  
        title = "Dunst";
        class = "Dunst";
  
        corner_radius = 10;
        timeout = 5;
      };
  
      urgency_low ={
        background = lib.mkForce "#${config.lib.stylix.colors.base00}";
        foreground = lib.mkForce "#${config.lib.stylix.colors.base05}";
	frame_color = lib.mkForce "#${config.lib.stylix.colors.base05}";
      };
  
      urgency_normal = {
        background = lib.mkForce "#${config.lib.stylix.colors.base00}";
        foreground = lib.mkForce "#${config.lib.stylix.colors.base05}";
	frame_color = lib.mkForce "#${config.lib.stylix.colors.base05}";
      };
  
      urgency_critical = {
        background = lib.mkForce "#${config.lib.stylix.colors.base00}";
        foreground = lib.mkForce "#${config.lib.stylix.colors.base05}";
        frame_color = lib.mkForce "#${config.lib.stylix.colors.base05}";
      };
    };
  };
}
