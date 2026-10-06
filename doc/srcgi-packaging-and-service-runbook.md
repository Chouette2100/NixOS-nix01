# NixOS 自前プログラムのパッケージ化とサービス化 手順書（SRCGI実績ベース）

作成日: 2026-10-06
対象: このリポジトリで flake + systemd により自前プログラムを運用する場合

---

## 1. 目的

この手順書は、SRCGI で実施した流れをテンプレート化し、同様のプログラム（約10本）へ横展開するためのものです。

今回の前提:
- 実行時に必要なファイル（例: config.yaml, cidr.txt など）がまだ未配置でもよい
- まずは「パッケージがビルドできること」「サービス登録できること」「起動エラーログが確認できること」を成功条件とする

---

## 2. 先に結論（今回のハマりどころ）

- nixos-rebuild switch だけでは、参照されない独立 package はビルドされない
- flake の package は outputs.packages に公開しないと検証しづらい
- vendorHash は fakeHash で一度ビルドして実値に置き換える
- src に絶対パスを使う場合、nixos-rebuild は --impure が必要
- systemd サービスで外部コマンドを使う場合、environment.systemPackages とは別に service 側の path 指定が必要
- systemd で append ログ出力を指定する場合、出力先ファイル/ディレクトリ条件が合わないと status=209/STDOUT でアプリ起動前に落ちる
- 実行時ファイルが未配置なら、サービスは起動後に失敗して failed になる（この段階では想定内）
- 設定ファイルとデータファイルがそろえば、同じ service 定義のまま正常起動できる

---

## 3. 実装済み参照箇所（SRCGI）

- flake 側 package 定義: [flake.nix](../flake.nix)
- service 定義: [modules/service.nix](../modules/service.nix)
- ビルドスクリプト: [build.sh](../build.sh)

---

## 4. 標準作業手順（1本あたり）

### 4-1. flake に package を定義する

1. let 内に package 定義を追加する
2. outputs 側で packages.x86_64-linux.<name> として公開する
3. サブディレクトリ構成の Go プロジェクトは modRoot を使う
4. 初回は vendorHash = nixpkgs.lib.fakeHash; とする

例（SRCGI）:

```nix
# let 内
srcgiPackage = nixpkgs.legacyPackages.x86_64-linux.buildGoModule {
  pname = "srcgi";
  version = "2.23.0";
  src = /home/chouette/go;
  modRoot = "src/SRCGI";
  vendorHash = nixpkgs.lib.fakeHash;
  doCheck = false;
};

# outputs 内
packages.x86_64-linux.srcgi = srcgiPackage;
```

### 4-2. 正しい vendorHash を確定する

1. 以下で package 単体ビルド:

```bash
nix build .#packages.x86_64-linux.srcgi --impure
```

2. hash mismatch の got: sha256-... を控える
3. flake の vendorHash を実値へ置換する
4. 再度ビルドして成功を確認する

```bash
nix build .#packages.x86_64-linux.srcgi --impure -L
```

### 4-3. service を有効化する

1. service 定義のコメントを外す
2. ExecStart を self.packages.${pkgs.system}.<name> 参照にする
3. WorkingDirectory を /var/lib/<name> にする
4. StateDirectory = "<name>"; を設定する
5. 必要な環境変数を Environment または environment で明示する
6. 外部コマンドを内部で使う場合は path = [ ... ]; で実行PATHへ追加する
7. 現段階は Restart = "no"; にする（再起動ループ防止）

例（SRCGI）:

```nix
systemd.services.srcgi = {
  description = "SRCGI";
  after = [ "network-online.target" ];
  wants = [ "network-online.target" ];
  wantedBy = [ "multi-user.target" ];

  path = [ pkgs.sops pkgs.age ];

  serviceConfig = {
    Type = "simple";
    User = "chouette";
    Group = "users";
    WorkingDirectory = "/var/lib/srcgi";
    Environment = [
      "HTTPPORT=8000"
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
    ];
    ExecStart = "${self.packages.${pkgs.system}.srcgi}/bin/SRCGI";
    StateDirectory = "srcgi";
    Restart = "no";
  };
};
```

補足:
- `environment.systemPackages = [ pkgs.sops pkgs.age ];` だけでは systemd サービスの PATH には入らない
- アプリが `sops` や `age` を `exec` する場合は `path = [ pkgs.sops pkgs.age ];` が必要
- `CONFIG_PATH` のような環境変数が必要なアプリでは、service 定義に明示しておく

### 4-4. self を module に渡す

service 側で self.packages を使うため、flake の specialArgs に self を渡す:

```nix
specialArgs = {
  inherit hostName inputs self;
};
```

### 4-5. 適用と確認

```bash
sudo nixos-rebuild switch --flake .#nix01 --impure
sudo systemctl status srcgi.service --no-pager -n 40
sudo journalctl -u srcgi.service -n 80 --no-pager
ls -la /var/lib/srcgi
```

期待結果（この段階）:
- service は登録される
- 1回起動して、必要ファイル不足エラーで failed になる
- Restart=no のため自動再起動ループしない

必要ファイル配置後の期待結果:
- service が `active (running)` になる
- journal に初期化ログが出力される
- Web サーバーとして応答できる

---

## 5. build.sh 運用ルール

src に絶対パスを使っている間は pure evaluation で落ちるため、switch には --impure を付ける。

確認箇所:
- [build.sh](../build.sh)

---

## 6. 横展開テンプレート（置換して使う）

置換対象:
- NAME: プログラム名（例: srcgi）
- VERSION: バージョン
- SRC_ROOT: ソースルート（例: /home/chouette/go）
- MOD_ROOT: Go module ルート（例: src/SRCGI）
- BIN_NAME: 実行バイナリ名

```nix
NAMEPackage = nixpkgs.legacyPackages.x86_64-linux.buildGoModule {
  pname = "NAME";
  version = "VERSION";
  src = SRC_ROOT;
  modRoot = "MOD_ROOT";
  vendorHash = "sha256-REPLACE_ME";
  doCheck = false;
};

packages.x86_64-linux.NAME = NAMEPackage;

systemd.services.NAME = {
  wantedBy = [ "multi-user.target" ];
  after = [ "network-online.target" ];
  wants = [ "network-online.target" ];

  path = [ pkgs.sops pkgs.age ];

  serviceConfig = {
    Type = "simple";
    User = "chouette";
    Group = "users";
    WorkingDirectory = "/var/lib/NAME";
    Environment = [
      "PORT=REPLACE_ME"
      "SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt"
    ];
    ExecStart = "${self.packages.${pkgs.system}.NAME}/bin/BIN_NAME";
    StateDirectory = "NAME";
    Restart = "no";
  };
};
```

---

## 7. トラブルシュート早見表

- 症状: nixos-rebuild は Done だが package の hash エラーが出ない
  - 原因: package が参照されておらずビルドされていない
  - 対応: nix build .#packages.x86_64-linux.<name> を実行

- 症状: error: access to absolute path ... is forbidden in pure evaluation mode
  - 原因: flake 評価で絶対パス src を使っている
  - 対応: --impure 付きで実行する

- 症状: status=209/STDOUT
  - 原因: StandardOutput/StandardError の append 先が不適切
  - 対応: まずは journal 出力運用に戻す（指定を外す）

- 症状: err=sops --decrypt failed: exec: "sops": executable file not found in $PATH.
  - 原因: systemd サービスの PATH に sops が入っていない
  - 対応: service 定義に path = [ pkgs.sops pkgs.age ]; を追加する

- 症状: open cidr.txt: no such file or directory
  - 原因: 実行時ファイルが未配置
  - 対応: 現段階では想定内。必要ファイルを /var/lib/<name>/ に配置後、再検証

- 症状: 設定ファイルを追加したら起動した
  - 原因: 直前の失敗原因が設定不足だった
  - 対応: journal を見て不足ファイル名を特定し、WorkingDirectory 配下へ配置する

---

## 8. 本番移行時のチェック項目

- Restart を no から on-failure または always に戻す
- 必要ファイル配置（所有者/権限含む）
- CONFIG_PATH など環境変数の最終化
- path に追加したコマンド依存（sops, age, mysql, bash など）の棚卸し
- systemd hardening（必要なら DynamicUser, ProtectSystem, ReadWritePaths など）
- ログ出力先の設計（journal のままか、ファイル分離するか）

---

## 9. 参考コマンド（SRCGI）

```bash
# package 単体ビルド
nix build .#packages.x86_64-linux.srcgi --impure -L

# 設定適用
sudo nixos-rebuild switch --flake .#nix01 --impure

# サービス状態
sudo systemctl status srcgi.service --no-pager -n 40

# ログ確認
sudo journalctl -u srcgi.service -n 80 --no-pager
journalctl --user --since="2026-10-06 15:00"
```
