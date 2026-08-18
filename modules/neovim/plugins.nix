{ ... }:
{
  # プラグイン設定
  programs.nixvim.plugins = {

    # 2. キー操作をガイドするメニュー (which-key) を有効化
    which-key = {
      enable = true;
      # メニューの見た目や挙動を細かく設定できますが、まずはデフォルトでOK

      # デバッグ用のキーマップ（例）
      settings.spec = [
        {
          __unkeyed-1 = "<leader>d";
          group = "Debug";
        }
      ];
    };

    # --- デバッグ設定 (DAP) ---
    dap = {
      enable = true;
      # nixvim 更新に伴い extensionConfig は廃止されました。
      # 代わりに plugins.dap.luaConfig.content（トップレベル）で追加設定しています。

      #  extensions = {
      #    dap-ui.enable = true;    # デバッグ画面のUI
      #    dap-go.enable = true;    # Go用設定の自動化
      #    dap-virtual-text.enable = true; # 変数の値をコード上に表示
      #  };
    };
    dap-ui.enable = true; # デバッグ画面のUI
    dap-go.enable = true; # Go用設定の自動化
    dap-virtual-text.enable = true; # 変数の値をコード上に表示

    # # デバッグ用のキーマップ（例）
    # which-key.settings.spec = [
    #   {
    #     __unkeyed-1 = "<leader>d";
    #     group = "Debug";
    #   }
    # ];

    # 見た目系
    lualine.enable = true; # ステータスライン
    bufferline.enable = true; # タブバー
    treesitter.enable = true; # シンタックスハイライト

    # 開発便利系
    telescope.enable = true; # ファイル検索・曖昧検索
    oil.enable = true; # ファイル操作（エディタ感覚でファイル操作できる）
    web-devicons.enable = true;

    # LSP (ここがnixvimの真骨頂)
    lsp = {
      enable = true;
      servers = {
        gopls.enable = true; # Go用
        nixd.enable = true; # Nix用 (nilより最近は人気)
        lua_ls.enable = true; # Lua用
      };
    };

    # 補完系
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings.sources = [
        { name = "nvim_lsp"; }
        { name = "path"; }
        { name = "buffer"; }
      ];
      settings.mapping = {
        "<C-Space>" = "cmp.mapping.complete()";
        "<CR>" = "cmp.mapping.confirm({ select = true })";
        "<Tab>" = "cmp.mapping.select_next_item()";
      };
    };

    toggleterm = {
      enable = true;
      settings = {
        open_mapping = "[[<C-t>]]"; # Ctrl + t でターミナルを出し入れ
        direction = "horizontal"; # 下側に開く (float や vertical も可能)
        size = 15;
      };
    };

    # 3. ファイラー (Neo-tree) の導入 (LazyVimで使われているもの)
    neo-tree = {
      enable = true;
      # closeIfLastWindow = true;
      settings.close_if_last_window = true; # Neo-treeが最後のウィンドウなら自動で閉じる設定
    };

  };

  # DAP の追加設定（extensionConfig 後継）
  programs.nixvim.plugins.dap.luaConfig.content = ''
    -- プロジェクトの .vscode/launch.json を読み込む設定
    require('dap.ext.vscode').load_launchjs(nil, {
      -- 言語名と、dapのアダプタ名を紐付けます
      go = {'go'},
      cpp = {'cppdbg'},
      python = {'python'},
    })
  '';
}
