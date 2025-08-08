{pkgs, lib, config, inputs, ...}:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = false;
      format = "$os\$hostname\$username\$directory\$git_branch\$git_commit\$git_status\$fill\$nix_shell\$aws\$c\$cpp\$golang\$java\$lua\$nodejs\$package\$python\$rust\$zig\$docker_context\$jobs\$cmd_duration\$line_break\$character";
      # Basic Setup
      shell = {
        disabled = false;
	format = "$indicator";
        fish_indicator = "[FISH](bright-white) ";
	bash_indicator = "[BASH](bright-white) ";
	zsh_indicator = "[ZSH](bright-white) ";
      };

      username = {
        style_user = "bright-white bold";
        style_root = "bright-red bold";
      };

      hostname = {
        # style = "bright-green bold";
        ssh_only = true;
	ssh_symbol =  " ";
      };

      nix_shell = {
        symbol = " ";
        # format = "[$symbol$name]($style) ";
        # style = "bright-purple bold";
      };

      git_branch = {
        only_attached = true;
        # format = "[$symbol$branch]($style) ";
        symbol = "";
        # style = "bright-yellow bold";
      };

      git_commit = {
        only_detached = true;
	tag_symbol =  " ";
        format = "[$symbol$hash]($style) ";
        # style = "bright-yellow bold";
      };

      git_state = {
        # style = "bright-purple bold";
      };

      git_status = {
        # style = "bright-green bold";
      };

      directory = {
        read_only = "󰌾 ";
        truncation_length = 0;
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "bright-blue";
      };

      jobs = {
        style = "bright-green bold";
      };

      character = {
        success_symbol = "[\\$](bright-green bold)";
        error_symbol = "[\\$](bright-red bold)";
      };

      # Languages
      aws = {
        symbol = " ";
      };

      c = {
        symbol = " "; 
      };

      cpp = {
        symbol = " ";
      };

      docker_context = {
        symbol = " ";
      };

      golang = {
        symbol = " ";
      };

      java = {
        symbol = " ";
      };

      lua = {
        symbol = " ";
      };

      memory_usage = {
        symbol = " ";
      };

      nodejs = {
        symbol = " ";
      };

      package = {
        symbol = "󰏗 ";
      };

      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        AlmaLinux = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CachyOS = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Kali = " ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        Nobara = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        RockyLinux = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Void = " ";
        Windows = "󰍲 ";
      };

      python = {
        symbol = " ";
      };

      rust = {
        symbol =  "󱘗 ";
      };

      zig = {
        symbol = " ";
      };
    };
  };
}
