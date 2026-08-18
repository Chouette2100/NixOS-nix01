{ ... }:
{
    # プラグイン設定
    programs.nixvim.opts = {
      number = true;         # 行番号表示
      relativenumber = true; # 相対行番号
      shiftwidth = 2;        # インデント幅
      tabstop = 2;
      expandtab = true;      # タブをスペースに
      smartindent = true;
      ignorecase = true;     # 検索時に大文字小文字を無視
      smartcase = true;
      termguicolors = true;  # 真彩色対応
      completeopt = "menu,menuone,noselect"; # CopilotChat / cmp の補完を安定させる
    };
}
