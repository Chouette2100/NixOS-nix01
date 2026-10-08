# UpdateUserSetProperty(sruusp) を Nix パッケージ化し user-timer で起動する手順書

作成日: 2026-10-07  
対象: /home/chouette/go/src/UpdateUserSetProperty を Home Manager の user systemd timer で定期実行する

---

## 1. 目的

- /home/chouette/go/src/UpdateUserSetProperty を Nix パッケージ化する
- 実行に必要なファイルを [sruusp-assets.yaml](../sruusp-assets.yaml) から /var/lib/sruusp に展開する
- UpdateUserSetProperty を user-timer（実行ユーザー: chouette）として定期起動する

---

## 2. 参照した実装

- SRCGI の実績: [srcgi-packaging-and-service-runbook.md](srcgi-packaging-and-service-runbook.md)
- SRGCE の実績: [srgce-packaging-and-userTimer.md](srgce-packaging-and-userTimer.md)
- 共通 user-timer 実装: [modules/user-timers/default.nix](../modules/user-timers/default.nix), [modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix)

---

## 3. 設計ポイント

1. UpdateUserSetProperty は system service ではなく user service（oneshot）で起動する。
2. 実行ディレクトリは /var/lib/sruusp を使用する。
3. 実行直前に `manifest.tsv` を読み、read-only 資材は symlink、write 資材は実体ファイルとして配置する。
4. 必須環境変数を user service 側に明示する。
5. 実行用の shell スクリプトは `run.sh` をそのまま使い、個別の実行時引数だけを timer で渡す。

必要な環境変数:

- `SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt`
- `DBHOST=localhost`
- `DBPORT=3306`
- `WORKDR=/var/lib/sruusp`

---

## 4. 変更した箇所

### 4-1. Package 追加

[flake.nix](../flake.nix) に以下を追加した。

- `sruuspPackage`
- `sruuspAssets`
- `packages.x86_64-linux.sruusp`
- `packages.x86_64-linux.sruuspAssets`

実装の要点:

- Go module root: `src/UpdateUserSetProperty`
- manifest: [sruusp-assets.yaml](../sruusp-assets.yaml)
- package は `buildGoModule` で構築
- 初回ビルドで `vendorHash` mismatch を確認し、`got:` の値を反映して完了した

### 4-2. user-timer 定義追加

[modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix) に以下を追加した。

- `sruusp-main`
- `sruusp-weekly`
- `sruusp-monthly`
- `sruusp-event`

各ジョブは次を実行する。

- `manifest.tsv` を走査
- `ro` の資材は symlink 作成
- `write` の資材は空ファイル作成と mode 設定
- `run.sh` を実行

### 4-3. tmpfiles に /var/lib/sruusp を準備

[modules/service.nix](../modules/service.nix) に以下を追加した。

```nix
systemd.tmpfiles.rules = [
  "d /var/lib/srgce 0755 chouette users - -"
  "d /var/lib/sruusp 0755 chouette users - -"
];
```

### 4-4. assets manifest 整合修正

[sruusp-assets.yaml](../sruusp-assets.yaml) では実際のファイル名に合わせ、`DBConfig.enc.yml` と `Env.yml` を指定した。

---

## 5. 実行時の cron 相当

要件の cron と同時刻に起動するように定義した。

```cron
# m h  dom mon dow   command
45 0 * * 1 /var/lib/sruusp/run.sh Sr 220 Pt 100000 Rk daily last 10 Rk weekly last 15
45 0 * * 2-7 /var/lib/sruusp/run.sh Sr 220 Pt 100000 Rk daily last 10
0 2 1 * * /var/lib/sruusp/run.sh Rk monthly last 15
45 13 * * * /var/lib/sruusp/run.sh Sr 220 Pt 100000 Ev 500000
10 15 * * * /var/lib/sruusp/run.sh Sr 220 Pt 100000 Ev 500000
```

実際の user timer では以下の OnCalendar に変換した。

- `sruusp-main`: 毎日 00:45
- `sruusp-weekly`: 月曜日 00:45
- `sruusp-monthly`: 毎月 1日 02:00
- `sruusp-event`: 毎日 13:45 / 15:10

---

## 6. 反映手順

1. ビルド確認

```bash
cd /home/chouette/NixOS-nix01
nix build .#packages.x86_64-linux.sruusp --impure -L
```

2. vendorHash mismatch が出たら値を反映して再実行

```bash
nix build .#packages.x86_64-linux.sruusp --impure -L
```

3. システム適用

```bash
sudo nixos-rebuild switch --flake .#nix01 --impure
```

4. user timer を再読込して確認

```bash
systemctl --user daemon-reload
systemctl --user list-timers --all | grep sruusp
systemctl --user status sruusp-main.timer --no-pager
systemctl --user status sruusp-weekly.timer --no-pager
systemctl --user status sruusp-monthly.timer --no-pager
systemctl --user status sruusp-event.timer --no-pager
```

5. 実行ログ確認

```bash
journalctl --user -u sruusp-main.service -n 80 --no-pager
journalctl --user -u sruusp-weekly.service -n 80 --no-pager
journalctl --user -u sruusp-monthly.service -n 80 --no-pager
journalctl --user -u sruusp-event.service -n 80 --no-pager
```

---

## 7. 確認済みの検証結果

次のコマンドを実行して、package と timer 定義が生成できることを確認した。

```bash
cd /home/chouette/NixOS-nix01
nix build .#packages.x86_64-linux.sruusp --impure -L
nix eval .#nixosConfigurations.nix01.config.home-manager.users.chouette.systemd.user.timers.sruusp-main.Timer.OnCalendar --impure --json
nix eval .#nixosConfigurations.nix01.config.home-manager.users.chouette.systemd.user.timers.sruusp-event.Timer.OnCalendar --impure --json
nix eval .#nixosConfigurations.nix01.config.home-manager.users.chouette.systemd.user.timers.sruusp-monthly.Timer.OnCalendar --impure --json
```

出力は以下の通り。

```json
[
  "Mon *-*-* 00:45:00",
  "Tue *-*-* 00:45:00",
  "Wed *-*-* 00:45:00",
  "Thu *-*-* 00:45:00",
  "Fri *-*-* 00:45:00",
  "Sat *-*-* 00:45:00",
  "Sun *-*-* 00:45:00"
]
```

```json
[
  "*-*-* 13:45:00",
  "*-*-* 15:10:00"
]
```

```json
[
  "*-*-01 02:00:00"
]
```

---

## 8. トラブルシュート

### 8-1. build 時に vendorHash mismatch

対応:

```bash
nix build .#packages.x86_64-linux.sruusp --impure
```

`got: sha256-...` を [flake.nix](../flake.nix) の `vendorHash` に反映して再実行する。

### 8-2. /var/lib/sruusp へ書けない

対応:

```bash
sudo systemd-tmpfiles --create
```

### 8-3. DBConfig.enc.yml が見つからない

対応:

- [sruusp-assets.yaml](../sruusp-assets.yaml) の `src` と実ファイル名が一致しているか確認する
- `DBConfig.enc.yml` が実際に存在するか確認する

### 8-4. SOPS 復号に失敗する

対応:

```bash
ls -l /home/chouette/.config/age/key2.txt
```

```bash
echo $SOPS_AGE_KEY_FILE
```

鍵ファイルの存在と権限、環境変数を確認する。

---

## 9. 運用ポイント

- user-timer ジョブは [modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix) に同形式で追加できる
- 資産配布は YAML で `file` / `dir` / `rename` / `write` を共通運用できる
- 実行環境変数は `job.environment` に明示することで管理しやすい
- 実行ファイル自体は Nix package で管理するので、環境差分を最小化できる

---

## 10. まとめ

今回の実装で、UpdateUserSetProperty は Nix パッケージ化され、`/var/lib/sruusp` に必要なファイルが展開されてから Home Manager の user timer で定期実行されるようになった。

中心となる構成は次の 3 点である。

- `self.packages.${pkgs.system}.sruusp` で Go バイナリを管理
- `sruuspAssets` の manifest で実行時資材を `/var/lib/sruusp` に展開
- `systemd.user.timers` で cron 相当の実行を定義

これで、実行環境の再現性と保守性を高めた構成が完成した。
