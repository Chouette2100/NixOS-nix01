# SRGCE を Nix パッケージ化し user-timer で起動する手順書

作成日: 2026-10-07  
対象: このリポジトリで SRGCE を Home Manager の user systemd timer で定期実行する場合

---

## 1. 目的

- /home/chouette/go/src/SRGCE を Nix パッケージ化する
- 実行に必要なファイルを srgce-assets.yaml から /var/lib/srgce に展開する
- SRGCE を user-timer（実行ユーザー: chouette）として定期起動する

---

## 2. 参照した実装

- SRCGI の手順書: doc/srcgi-packaging-and-service-runbook.md
- user-timer の共通実装: modules/user-timers/default.nix, modules/user-timers/jobs.nix

---

## 3. 今回の設計ポイント

1. SRGCE は system service ではなく user service（oneshot）で起動する。
2. 実行ディレクトリは /var/lib/srgce を使用する。
3. 実行直前に manifest.tsv を読み、read-only 資材は symlink、write 資材は実体ファイルとして配置する。
4. 必須環境変数を user service 側に明示する。

必要な環境変数:

- SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt
- DBHOST=localhost
- DBPORT=3306

---

## 4. 変更箇所

### 4-1. SRGCE パッケージ追加

flake.nix に以下を追加する。

- packages.x86_64-linux.srgce
- packages.x86_64-linux.srgceAssets

要点:

- buildGoModule の modRoot は src/SRGCE
- srgceAssets は /home/chouette/go/src/SRGCE/srgce-assets.yaml を manifest として読み込む
- Home Manager 側で self.packages を参照できるよう extraSpecialArgs に self を渡す

### 4-2. user-timer 定義拡張

modules/user-timers/default.nix:

- jobs.nix を関数 import に変更（pkgs と self を渡す）
- 各 job に environment を指定できるように拡張

modules/user-timers/jobs.nix:

- 既存ジョブに加えて srgce-main を追加
- script は writeShellScript で生成し、次を実行:
  - srgceAssets の manifest.tsv を走査
  - /var/lib/srgce へ symlink/実体ファイルを配置
  - ${self.packages.${pkgs.system}.srgce}/bin/SRGCE を実行

### 4-3. /var/lib/srgce の作成

modules/service.nix:

- systemd.tmpfiles.rules に以下を追加
  - d /var/lib/srgce 0755 chouette users - -

これで user service 実行ユーザー chouette が作業ディレクトリを扱える。

### 4-4. assets 定義の整合修正

/home/chouette/go/src/SRGCE/srgce-assets.yaml の記載を実ファイル名に合わせて修正。

- DBConfig.enc.yaml -> DBConfig.enc.yml
- srgce.sh.VPS -> srgce_VPS.sh（dest は srgce.sh のまま）

---

## 5. タイマー設定（cron 相当）

要求された cron:

```cron
# m h  dom mon dow   command
5-59/30 * * * *
20-59/30 18-19/1 * * *
```

systemd OnCalendar では次の 2 本で表現する。

```nix
calendars = [
  "*-*-* *:05,35:00"
  "*-*-* 18,19:20,50:00"
];
```

注:

- 1本目で毎時 05 分・35 分
- 2本目で 18 時台/19 時台に 20 分・50 分を追加

---

## 6. 適用手順

1. SRGCE package の vendorHash を確定（初回のみ）

```bash
nix build .#packages.x86_64-linux.srgce --impure
```

2. 表示された hash mismatch の got: sha256-... を flake.nix の srgce vendorHash に反映

3. 再ビルド確認

```bash
nix build .#packages.x86_64-linux.srgce --impure -L
```

4. システム適用

```bash
sudo nixos-rebuild switch --flake .#nix01 --impure
```

5. user timer の確認

```bash
systemctl --user daemon-reload
systemctl --user list-timers --all | grep srgce-main
systemctl --user status srgce-main.timer --no-pager
systemctl --user status srgce-main.service --no-pager
journalctl --user -u srgce-main.service -n 80 --no-pager
```

---

## 7. トラブルシュート

- 症状: build 時に vendorHash mismatch
  - 対応: got: sha256-... を vendorHash に反映して再ビルド

- 症状: /var/lib/srgce へ書けない
  - 対応: tmpfiles 反映後に再起動、または sudo systemd-tmpfiles --create を実行

- 症状: DBConfig.enc.yml が見つからない
  - 対応: srgce-assets.yaml の src 名と実ファイル名を再確認

- 症状: sops 復号エラー
  - 対応: SOPS_AGE_KEY_FILE のパスと鍵ファイル権限を確認

---

## 8. 今後の横展開ポイント

- user-timer ジョブは jobs.nix へ同形式で追加すれば増やせる
- assets 配布は YAML で file / rename / dir / write を共通運用できる
- 実行環境変数は job.environment に明示することで管理しやすい