{ ... }:
{
    # キーマップ設定
    programs.nixvim.keymaps = [

      # デバッグ開始・継続
      { mode = "n"; key = "<F5>"; action = "<cmd>lua require('dap').continue()<CR>"; options.desc = "Debug: Start/Continue"; }
      { mode = "n"; key = "<F10>"; action = "<cmd>lua require('dap').step_over()<CR>"; options.desc = "Debug: Step Over"; }
      { mode = "n"; key = "<F11>"; action = "<cmd>lua require('dap').step_into()<CR>"; options.desc = "Debug: Step Into"; }
      { mode = "n"; key = "<leader>db"; action = "<cmd>lua require('dap').toggle_breakpoint()<CR>"; options.desc = "Debug: Toggle Breakpoint"; }
      { mode = "n"; key = "<leader>du"; action = "<cmd>lua require('dapui').toggle()<CR>"; options.desc = "Debug: Toggle UI"; }

      #   ウィンドウ移動を Ctrl + hjkl に割り当てる
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; }

      #  ウィンドウサイズ変更を Alt + 矢印 に割り当てる
      { mode = "n"; key = "<A-Up>"; action = "<cmd>resize +2<cr>"; }
      { mode = "n"; key = "<A-Down>"; action = "<cmd>resize -2<cr>"; }
      { mode = "n"; key = "<A-Left>"; action = "<cmd>vertical resize -2<cr>"; }
      { mode = "n"; key = "<A-Right>"; action = "<cmd>vertical resize +2<cr>"; }

      # ターミナルモードで Esc を押すとノーマルモードに戻る
      { mode = "t"; key = "<Esc>"; action = "<C-\\><C-n>"; }
  
      # ターミナルモードから直接他のウィンドウへ移動できるようにする
      { mode = "t"; key = "<C-h>"; action = "<C-\\><C-n><C-w>h"; }
      { mode = "t"; key = "<C-j>"; action = "<C-\\><C-n><C-w>j"; }
      { mode = "t"; key = "<C-k>"; action = "<C-\\><C-n><C-w>k"; }
      { mode = "t"; key = "<C-l>"; action = "<C-\\><C-n><C-w>l"; }

      # スペース + ff でファイル検索 (Telescope)
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<CR>";
        options.desc = "Find Files";
      }

      # スペース + e でファイラー（Neo-tree）を開く
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<CR>";
        options = {
          desc = "Explorer (Neo-tree)";
        };
      }

      # スペース + / でライブグレップ（全文検索）
      {
        mode = "n";
        key = "<leader>/";
        action = "<cmd>Telescope live_grep<CR>";
        options = {
          desc = "Grep (Root Dir)";
        };
      }

      # Copilot Chat 関連のキーマップ
      # チャットウィンドウをトグル（開閉）する
      {
        mode = "n";
        key = "<leader>cc"; # Copilot Chat の略
        action = "<cmd>CopilotChatToggle<CR>";
        options = {
          desc = "Toggle Copilot Chat";
        };
      }

      # 選択した範囲に対して説明を求める（ビジュアルモード）
      {
        mode = "v";
        key = "<leader>ce"; # Copilot Explain
        action = "<cmd>CopilotChatExplain<CR>";
        options = {
          desc = "CopilotChat - Explain code";
        };
      }

      # 選択した範囲の修正案を出す（ビジュアルモード）
      {
        mode = "v";
        key = "<leader>cf"; # Copilot Fix
        action = "<cmd>CopilotChatFix<CR>";
        options = {
          desc = "CopilotChat - Fix code";
        };
      }

      # 自由入力でチャットを開く（現在のバッファの内容をコンテキストにする）
      {
        mode = "n";
        key = "<leader>cq"; # Copilot Quick chat
        action = ":CopilotChat "; # <CR>を入れないことで、コマンドラインに文字を入力できる状態で止める
        options = {
          desc = "CopilotChat - Quick prompt";
          silent = false; # コマンドを表示したいのでfalse
        };
      }
      
    ];
}
