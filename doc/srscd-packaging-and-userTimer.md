# SaveConfirmedData(srscd) を Nix パッケージ化し user-timer で起動する手順書

作成日: 2026-10-08  
対象: /home/chouette/go/src/SaveConfirmedData を Home Manager の user systemd timer で定期実行する

---

## 1. 目的

- /home/chouette/go/src/SaveConfirmedData を Nix パッケージ化する
- 実行に必要なファイルを [srscd-assets.yaml](../srscd-assets.yaml) から /var/lib/srscd に展開する
- `uinf.sh`, `sdat.sh`, `sdatP.sh` を user-timer（実行ユーザー: chouette）として定期起動する

---

## 2. 参照した実装

- SRGCE の実績: [srgce-packaging-and-userTimer.md](srgce-packaging-and-userTimer.md)
- SRCGI の実績: [srcgi-packaging-and-service-runbook.md](srcgi-packaging-and-service-runbook.md)
- 共通 user-timer 実装: [modules/user-timers/default.nix](../modules/user-timers/default.nix), [modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix)

---

## 3. 設計ポイント

1. SaveConfirmedData は system service ではなく user service（oneshot）で起動する。
2. 実行ディレクトリは /var/lib/srscd を使用する。
3. 実行直前に `manifest.tsv` を読み、read-only 資材は symlink、write 資材は実体ファイルとして配置する。
4. 必須環境変数を user service 側に明示する。
5. `uinf.sh`, `sdat.sh`, `sdatP.sh` はそのまま使い、`WORKDR` と `DBHOST` のみ timer 側で渡す。

必要な環境変数:

- `SOPS_AGE_KEY_FILE=/home/chouette/.config/age/key2.txt`
- `DBHOST=localhost`
- `DBPORT=3306`
- `WORKDR=/var/lib/srscd`

---

## 4. 実際に変更した箇所

### 4-1. package 追加

[flake.nix](../flake.nix) に以下を追加した。

- `srscdPackage`
- `srscdAssets`
- `packages.x86_64-linux.srscd`
- `packages.x86_64-linux.srscdAssets`

実装の要点:

- Go module root: `src/SaveConfirmedData`
- manifest: [srscd-assets.yaml](../srscd-assets.yaml)
- package は `buildGoModule` で構築
- 初回ビルドで `vendorHash` mismatch を確認し、`got:` の値を反映して完了した

### 4-2. user-timer 定義追加

[modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix) に以下を追加した。

- `srscd-uinf`
- `srscd-sdat`
- `srscd-sdatP`

各ジョブでは次を実行する。

- `manifest.tsv` を走査
- `ro` の資材は symlink 作成
- `write` の資材は実体ファイルを生成
- `SaveConfirmedData` バイナリを `/var/lib/srscd/SaveConfirmedData` に symlink
- `uinf.sh`, `sdat.sh`, `sdatP.sh` を起動

### 4-3. tmpfiles に /var/lib/srscd を準備

[modules/service.nix](../modules/service.nix) に以下を追加した。

```nix
systemd.tmpfiles.rules = [
  "d /var/lib/srgce 0755 chouette users - -"
  "d /var/lib/sruusp 0755 chouette users - -"
  "d /var/lib/srscd 0755 chouette users - -"
];
```

### 4-4. asset manifest 整合修正

[srscd-assets.yaml](../srscd-assets.yaml) では、実ファイル名に合わせて以下を定義した。

- `DBConfig.enc.yml`
- `Env.yml`
- `uinf.sh`
- `sdat.sh`
- `sdatP.sh`

---

## 5. 実行時の cron 相当

元の cron は以下の通り。

```cron
# m h  dom mon dow   command
25 2 * * * /var/lib/srscd/uinf.sh
5-59/30 12 * * * /var/lib/srscd/sdat.sh
15 0 * * * /var/lib/srscd/sdatP.sh
15 20 * * * /var/lib/srscd/sdatP.sh
15 22 * * * /var/lib/srscd/sdatP.sh
15 18 * * * /var/lib/srscd/sdatP.sh
15 13 * * * /var/lib/srscd/sdatP.sh
```

この実装では systemd `OnCalendar` に変換している。

- `srscd-uinf`: `*-*-* 02:25:00`
- `srscd-sdat`: `*-*-* 12:05,35:00`
- `srscd-sdatP`:
  - `*-*-* 00:15:00`
  - `*-*-* 13:15:00`
  - `*-*-* 18:15:00`
  - `*-*-* 20:15:00`
  - `*-*-* 22:15:00`

---

## 6. 反映手順

1. ビルド確認

```bash
cd /home/chouette/NixOS-nix01
nix build .#packages.x86_64-linux.srscd --impure -L
```

2. `vendorHash` mismatch が出た場合

```bash
nix build .#packages.x86_64-linux.srscd --impure -L
```

表示された `got: sha256-...` を [flake.nix](../flake.nix) の `vendorHash` に反映して再実行する。

3. システム適用

```bash
sudo nixos-rebuild switch --flake .#nix01 --impure
```

4. user timer を再読込して確認

```bash
systemctl --user daemon-reload
systemctl --user list-timers --all | grep srscd
systemctl --user status srscd-uinf.timer --no-pager
systemctl --user status srscd-sdat.timer --no-pager
systemctl --user status srscd-sdatP.timer --no-pager
```

5. 実行ログ確認

```bash
journalctl --user -u srscd-uinf.service -n 80 --no-pager
journalctl --user -u srscd-sdat.service -n 80 --no-pager
journalctl --user -u srscd-sdatP.service -n 80 --no-pager
```

---

## 7. 確認済みの検証結果

実際に以下を実行して確認した。

```bash
cd /home/chouette/NixOS-nix01
nix build .#packages.x86_64-linux.srscd --impure -L
nix eval .#nixosConfigurations.nix01.config.home-manager.users.chouette.systemd.user.timers.srscd-uinf.Timer.OnCalendar --impure --json
nix eval .#nixosConfigurations.nix01.config.home-manager.users.chouette.systemd.user.timers.srscd-sdat.Timer.OnCalendar --impure --json
nix eval .#nixosConfigurations.nix01.config.home-manager.users.chouette.systemd.user.timers.srscd-sdatP.Timer.OnCalendar --impure --json
```

出力結果:

```json
[
  "*-*-* 02:25:00"
]
```

```json
[
  "*-*-* 12:05,35:00"
]
```

```json
[
  "*-*-* 00:15:00",
  "*-*-* 13:15:00",
  "*-*-* 18:15:00",
  "*-*-* 20:15:00",
  "*-*-* 22:15:00"
]
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
nix build .#packages.x86_64-linux.srscd --impure
```

`got: sha256-...` を [flake.nix](../flake.nix) の `vendorHash` に反映し、再実行する。

### 8-2. /var/lib/srscd へ書けない

対応:

```bash
sudo systemd-tmpfiles --create
```

### 8-3. DBConfig.enc.yml が見つからない

対応:

- [srscd-assets.yaml](../srscd-assets.yaml) の `src` と実ファイル名が一致しているか確認する
- 実際に `DBConfig.enc.yml` が存在するか確認する

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

## 9. まとめ

今回の実装により、SaveConfirmedData は Nix パッケージ化され、`/var/lib/srscd` に必要なファイルが展開されたうえで、Home Manager の user timer から定期実行されるようになった。

動作の中心は次の 3 点である。

- `self.packages.${pkgs.system}.srscd` で Go バイナリを管理
- `srscdAssets` の manifest で実行時資材を `/var/lib/srscd` に展開
- `systemd.user.timers` で cron 相当の実行を定義

これで、SaveConfirmedData の実行環境が再現可能な形で構築された。
---

## 9. 運用ポイント

- user-timer ジョブは [modules/user-timers/jobs.nix](../modules/user-timers/jobs.nix) に同形式で追加できる
- 資産配布は YAML で `file` / `dir` / `rename` / `write` を共通運用できる
- 実行環境変数は `job.environment` に明示することで管理しやすい
- 実行ファイル自体は Nix package で管理するので、環境差分を最小化できる

---

## 10. まとめ

今回の実装で、UpdateUserSetProperty は Nix パッケージ化され、`/var/lib/srscd` に必要なファイルが展開されてから Home Manager の user timer で定期実行されるようになった。

中心となる構成は次の 3 点である。

- `self.packages.${pkgs.system}.srscd` で Go バイナリを管理
- `srscdAssets` の manifest で実行時資材を `/var/lib/srscd` に展開
- `systemd.user.timers` で cron 相当の実行を定義

これで、実行環境の再現性と保守性を高めた構成が完成した。
