{ inputs, ... }: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./keymaps.nix
    ./plugins.nix
    ./opts.nix
  ];

  programs.nixvim.nixpkgs.source = inputs.nixpkgs;

  programs.nixvim.version.enableNixpkgsReleaseCheck = false;

  programs.nixvim = {
    enable = true;
    defaultEditor = true; # $EDITOR を nvim に設定

    # 1. リーダーキーを「スペース」に設定 (LazyVimと同じ)
    globals.mapleader = " ";

    # 基本設定 (vim.opt.xxx) ==> modules/neovim/opts.nix に分割

    # キーマップ設定 ==> modules/neovim/keymaps.nix に分割

    # プラグイン設定 --> modules/neovim/plugins.nix に分割

    # カラースキーム
    colorschemes.catppuccin.enable = true;

  };
}
