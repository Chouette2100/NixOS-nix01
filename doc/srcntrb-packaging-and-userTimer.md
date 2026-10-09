# SRCntrb(srcntrb) を Nix パッケージ化し user-timer で起動する手順書

作成日: 2026-10-08  
対象: /home/chouette/go/src/SRCntrb を Home Manager の user systemd timer で定期実行する

---

## 1. 目的

- /home/chouette/go/src/SRCntrb を Nix パッケージ化する
- 実行に必要なファイルを [srcntrb-assets.yaml](../srcntrb-assets.yaml) から /var/lib/srcntrb に展開する
- `srcntrb.sh` を user-timer（実行ユーザー: chouette）として定期起動する

---

## 2. 参照した実装

- SaveConfirmedData の実績: [srscd-packaging-and-userTimer.md](srscd-packaging-and-userTimer.md)
- SRCGI の実績: [srcgi-packaging-and-service-runbook.md](srcgi-packaging-and-service-runbook.md)
- 共通 user-timer 実装: [modules/user-timers/default.nix](../modules/user-timers/default.nix), [modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix)

---

## 3. 設計ポイント

1. SRCntrb は system service ではなく user service（oneshot）で起動する。
2. 実行ディレクトリは /var/lib/srcntrb を使用する。
3. 実行直前に `manifest.tsv` を読み、read-only 資材は symlink、write 資材は実体ファイルとして配置する。
4. 必須環境変数を user service 側に明示する。
5. `srcntrb.sh` は実行可能にしておき、`WORKDR` と `DBHOST` を timer 側で渡す。
6. 実行時に `bash /var/lib/srcntrb/srcntrb.sh` を使うことで、read-only に配置されたファイルでも permission denied を避ける。

必要な環境変数:

- `SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt`
- `DBHOST=localhost`
- `DBPORT=3306`
- `WORKDR=/var/lib/srcntrb`

---

## 4. 実際に変更した箇所

### 4-1. package 追加

[flake.nix](../flake.nix) に以下を追加した。

- `srcntrbPackage`
- `srcntrbAssets`
- `packages.x86_64-linux.srcntrb`
- `packages.x86_64-linux.srcntrbAssets`

実装の要点:

- Go module root: `src/SRCntrb`
- manifest: [srcntrb-assets.yaml](../srcntrb-assets.yaml)
- package は `buildGoModule` で構築
- 初回ビルドで `vendorHash` mismatch を確認し、`got:` の値を反映して完了した

### 4-2. user-timer 定義追加

[modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix) に `srcntrb` を追加した。

実際の処理:

- `manifest.tsv` を走査
- `ro` の資材は symlink 作成
- `write` の資材は実体ファイルを生成
- `SRCntrb` バイナリを `/var/lib/srcntrb/SRCntrb` に symlink
- `bash /var/lib/srcntrb/srcntrb.sh` で起動する

> ここは `exec "/var/lib/srcntrb/srcntrb.sh"` ではなく `bash` 経由にしている。`srcntrb.sh` は read-only symlink 配置であるため、実行権限が落ちるケースがあり、bash 経由にすることで安定動作した。

### 4-3. tmpfiles に /var/lib/srcntrb を準備

[modules/service.nix](../modules/service.nix) に以下を追加した。

```nix
systemd.tmpfiles.rules = [
  "d /var/lib/srgce 0755 chouette users - -"
  "d /var/lib/sruusp 0755 chouette users - -"
  "d /var/lib/srscd 0755 chouette users - -"
  "d /var/lib/srcntrb 0755 chouette users - -"
];
```

### 4-4. asset manifest 定義

[srcntrb-assets.yaml](../srcntrb-assets.yaml) では、実ファイル名に合わせて以下を定義した。

- `DBConfig.enc.yml`
- `srcntrb.sh`

### 4-5. コピー/編集後に必ず実行権限を確認する

他のPC からファイルをコピーした場合や、`vi` で編集した場合は、実行権限が落ちていることがある。

```bash
ls -l /home/chouette/go/src/SRCntrb/srcntrb.sh
chmod 755 /home/chouette/go/src/SRCntrb/srcntrb.sh
```

`srcntrb.sh` は Nix の asset 経由で `/var/lib/srcntrb` に配布されるので、ここで権限を確保しておかないと、timer 実行時に `Permission denied` になる。

---

## 5. 実行時の cron 相当

元の実行は 1 時間ごとに `:28` 分で走る cron 相当で、実際の systemd timer は次の `OnCalendar` に変換した。

```nix
calendars = [
  "*-*-* *:28:00"
];
```

つまり実際の実行タイミングは:

- `srcntrb`: `*-*-* *:28:00`

---

## 6. 反映手順

1. ビルド確認

```bash
cd /home/chouette/NixOS-nix01
nix build .#packages.x86_64-linux.srcntrb --impure -L
```

2. `vendorHash` mismatch が出た場合

```bash
nix build .#packages.x86_64-linux.srcntrb --impure -L
```

表示された `got: sha256-...` を [flake.nix](../flake.nix) の `vendorHash` に反映して再実行する。

3. システム適用

```bash
sudo nixos-rebuild switch --flake .#nix01 --impure
```

4. timer 登録確認

```bash
systemctl --user list-timers --all | grep srcntrb
systemctl --user status srcntrb.timer --no-pager
```

5. 実行ログ確認

```bash
journalctl --user -u srcntrb.service -n 80 --no-pager
```

---

## 7. 実際に確認できた検証結果

実際に以下を実行して確認した。

```bash
cd /home/chouette/NixOS-nix01
nix build .#packages.x86_64-linux.srcntrb --impure -L
sudo nixos-rebuild switch --flake .#nix01 --impure
systemctl --user list-timers --all | grep srcntrb || true
```

結果:

- `nix build` は成功した
- `nixos-rebuild` は成功した
- timer は `srcntrb.timer` として登録されていた

`list-timers` の出力例:

```text
Thu 2026-10-08 14:28:00 JST  6min -  - srcntrb.timer srcntrb.service
```

---

## 8. トラブルシュート

### 8-1. build 時に vendorHash mismatch

症状:

```bash
error: hash mismatch in fixed-output derivation ...
```

対応:

```bash
nix build .#packages.x86_64-linux.srcntrb --impure -L
```

`got: sha256-...` を [flake.nix](../flake.nix) の `vendorHash` に反映して再実行する。

### 8-2. /var/lib/srcntrb へ書けない

対応:

```bash
sudo systemd-tmpfiles --create
```

### 8-3. `Permission denied` で `srcntrb.sh` が起動しない

症状:

```bash
bash: /var/lib/srcntrb/srcntrb.sh: Permission denied
```

代表的な原因:

- 他の PC からコピーしたときに実行権限が落ちている
- `vi` で作成・編集したときに権限が未設定
- パッケージ化後に `read-only` の symlink になっている

対応:

```bash
ls -l /home/chouette/go/src/SRCntrb/srcntrb.sh
chmod 755 /home/chouette/go/src/SRCntrb/srcntrb.sh
```

さらに、timer 側では以下のように bash から起動する。

```nix
exec ${pkgs.bash}/bin/bash "/var/lib/srcntrb/srcntrb.sh"
```

これにより、read-only symlink 配置でも実行できる。

### 8-4. DBConfig.enc.yml が見つからない

対応:

- [srcntrb-assets.yaml](../srcntrb-assets.yaml) の `src` と実ファイル名が一致しているか確認する
- 実際に `DBConfig.enc.yml` が存在するか確認する

### 8-5. SOPS 復号に失敗する

対応:

```bash
ls -l /home/chouette/.config/age/key2.txt
```

```bash
echo $SOPS_AGE_KEY_FILE
```

鍵ファイルの存在、権限、環境変数を確認する。

---

## 9. まとめ

今回の実装により、SRCntrb は Nix パッケージ化され、`/var/lib/srcntrb` に必要なファイルが展開されたうえで、Home Manager の user timer から定期実行されるようになった。

中心となる構成は次の 3 点である。

- `self.packages.${pkgs.system}.srcntrb` で Go バイナリを管理
- `srcntrbAssets` の manifest で実行時資材を `/var/lib/srcntrb` に展開
- `systemd.user.timers` で cron 相当の実行を定義

これで、SRCntrb の実行環境が再現可能な形で構築された。

---

## 10. 運用ポイント

- user-timer ジョブは [modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix) に同形式で追加できる
- 資産配布は YAML で `file` / `dir` / `rename` / `write` を共通運用できる
- 実行環境変数は `job.environment` に明示することで管理しやすい
- 実行ファイル自体は Nix package で管理するので、環境差分を最小化できる
