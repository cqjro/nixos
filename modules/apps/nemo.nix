{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nemo-with-extensions
  ];

  # Configure Nemo through dconf
  dconf.settings = {
    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-advanced-permissions = true;
      default-folder-viewer = "list-view";
      default-sort-order = "name";
      default-sort-in-reverse-order = false;
      inherit-folder-viewer = true;
      ignore-view-metadata = false;
      show-full-path-titles = true;
      show-new-folder-icon-toolbar = true;
      show-open-in-terminal-toolbar = true;
    };

    "org/nemo/window-state" = {
      sidebar-bookmark-breakpoint = 5;
      sidebar-width = 150;
      start-with-sidebar = true;
      start-with-status-bar = true;
      start-with-toolbar = true;
    };

    # Icon view settings
    "org/nemo/icon-view" = {
      # default-zoom-level = "standard";
      labels-beside-icons = false;
    };

    # List view settings
    "org/nemo/list-view" = {
      default-column-order = ["name" "size" "type" "date_modified"];
      default-visible-columns = ["name" "size" "type" "date_modified"];
      # default-zoom-level = "standard";
    };
  };

  # # Optional: Set Nemo as default file manager
  # xdg.mimeApps.defaultApplications = {
  #   "inode/directory" = "nemo.desktop";
  # };
}
