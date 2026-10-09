# SetEventIDofOldEvents(srsei) を GitHub リポジトリから取得して Nix パッケージ化する手順書

作成日: 2026-10-09  
対象: https://github.com/Chouette2100/SetEventIDofOldEvents.git を GitHub から取得し、Home Manager の user systemd timer で定期実行する

> この手順は、ローカルディレクトリ版から GitHub ソース版へ切り替える独立した手順書です。 
> 実際のソース直下ディレクトリ名は `SetEventIdOfOldEvents`（`Id` の小文字 `d`）で、生成されるバイナリ名は `SetEventIDofOldEvents`（`ID` の大文字）です。

---

## 1. 目的

- GitHub 版の `SetEventIDofOldEvents` を Nix の `src` として取得する
- そのソースを `buildGoModule` でパッケージ化する
- 実行に必要なファイルを [srsei-assets.yaml](../srsei-assets.yaml) から `/var/lib/srsei` に展開する
- `run.sh` を user-timer で定期起動する

---

## 2. この方法の狙い

ローカルディレクトリ方式は「既存の開発環境のソースをそのまま使う」ため、作業が速く簡便です。
一方で、GitHub リポジトリ方式は次の利点があります。

- ソースの取得元が明確
- 環境依存のローカルパスを避けられる
- バージョン固定がしやすい
- 再現性が高い
- 他の環境や CI でも同じ手順で再現できる

今回の利用対象は修正変更がほぼないため、サンプルとしては非常に適しています。

---

## 3. 変更対象

GitHub 版へ切り替える場合に主に変更するのは [flake.nix](../flake.nix) の `srseiPackage` と `srseiAssets` の `src` です。

---

## 4. GitHub 版の指定方法

`flake.nix` の該当箇所を次のように変更します。

```nix
      srseiSource = builtins.fetchGit {
        url = "https://github.com/Chouette2100/SetEventIDofOldEvents.git";
        rev = "f0abbdc24262d0e812bc875ebc3699bc8dbaac6c";
      };

      srseiPackage = nixpkgs.legacyPackages.x86_64-linux.buildGoModule {
        pname = "srsei";
        version = "200300";
        src = srseiSource;
        modRoot = ".";
        vendorHash = "sha256-0bA/PfvuyjIvfIo4rPXQwJOb2uHRNF7K0K1jGnU9qpM=";
        doCheck = false;
        postInstall = ''
          if [ -x "$out/bin/SetEventIdOfOldEvents" ] && [ ! -e "$out/bin/SetEventIDofOldEvents" ]; then
            mv "$out/bin/SetEventIdOfOldEvents" "$out/bin/SetEventIDofOldEvents"
          fi
        '';
      };
```

asset 側も同じく `src = srseiSource` に変更します。

```nix
    srseiAssets = nixpkgs.legacyPackages.x86_64-linux.runCommand "srsei-assets" {
      src = srseiSource;
      manifest = /home/chouette/NixOS-nix01/srsei-assets.yaml;
      nativeBuildInputs = [ pythonWithPyYAML ];
    } ''
```

---

## 5. `fetchGit` の動作とキャッシュの仕組み

GitHub から取得する方法では、Nix は `url` と `rev` を使ってソースを一意に識別し、その内容を Nix store に保存します。

つまり、基本的には次のような動作になります。

- 初回ビルド時: GitHub からソースをダウンロードして Nix store に保存する
- 同じ `url` と `rev` を指定した再ビルド: 保存済みのソースを使う
- `rev` が変わる/異なる: 新しいソースを取得して別の store path として保存する

このため、`fetchGit` は「毎回 GitHub へアクセスしているわけではなく、同じ内容を再利用する」設計になっています。

実務上は次のように理解するとわかりやすいです。

- `url` + `rev` が同じなら、再利用される
- そのため、通常は毎回ダウンロードされない
- ただし、`rev` が変わる、キャッシュが消える、`--impure` などで再評価される場合は再取得される

`rev` を固定していることで、ビルドの再現性も保たれます。これはこの方法の大きなメリットです。

---

## 6. 変更のポイント

### 5-1. `src = /home/chouette/...` から `fetchGit` へ

ローカル版では次のようにしていました。

```nix
src = /home/chouette/go;
modRoot = "src/SetEventIdOfOldEvents";
```

GitHub 版では次のようにします。

```nix
src = srseiSource;
modRoot = ".";
```

`modRoot = "."` にしているのは、GitHub から取得したリポジトリのルートに Go ソースが置かれているためです。

### 5-2. 取得元の rev を固定する

```nix
rev = "f0abbdc24262d0e812bc875ebc3699bc8dbaac6c";
```

このようにコミットを固定しておくと、将来リポジトリが変わってもビルドが安定します。

### 5-3. バイナリ名の調整

実際にはソース側のディレクトリ名とバイナリ名の差分があります。

- ディレクトリ名: `SetEventIdOfOldEvents`
- バイナリ名: `SetEventIDofOldEvents`

そのため、postInstall で次のようにリネームしています。

```nix
if [ -x "$out/bin/SetEventIdOfOldEvents" ] && [ ! -e "$out/bin/SetEventIDofOldEvents" ]; then
  mv "$out/bin/SetEventIdOfOldEvents" "$out/bin/SetEventIDofOldEvents"
fi
```

---

## 7. 反映手順

1. `flake.nix` を編集する
2. ビルドを試す

```bash
cd /home/chouette/NixOS-nix01
nix build .#packages.x86_64-linux.srsei --impure -L
```

3. `vendorHash` mismatch が出たら更新する

```bash
nix build .#packages.x86_64-linux.srsei --impure -L
```

表示された `got: sha256-...` を `vendorHash` に反映して再実行する。

4. asset もビルドする

```bash
nix build .#packages.x86_64-linux.srseiAssets --impure -L
```

5. 設定を適用する

```bash
sudo nixos-rebuild switch --flake .#nix01 --impure
```

6. timer を確認する

```bash
systemctl --user list-timers --all | grep srsei
systemctl --user status srsei.timer --no-pager
```

7. 実行ログを確認する

```bash
journalctl --user -u srsei.service -n 80 --no-pager
```

---

## 8. 実際に確認できたこと

実際にこの方法で確認した結果は次の通りです。

- GitHub からソースを取得してビルドに成功した
- `buildGoModule` でパッケージ化できた
- `srsei` user-timer が有効化された
- `systemctl --user start srsei.service` の実行が成功した
- `journalctl --user -u srsei.service` に `Finished User timer job: srsei.` が出力された

つまり、GitHub リポジトリを入力にする方法でも今回の Nix パッケージ化は十分に実用的です。

---

## 9. ローカル版と GitHub 版の違い

### ローカル版
- 速い
- 既存の作業をすぐに反映できる
- 環境依存が強い

### GitHub 版
- 再現性が高い
- バージョン固定が容易
- 実運用に向く
- 共有時に安全

今回の `SetEventIDofOldEvents` は修正がほぼないため、GitHub ベースの方式を採用しても十分に自然です。

---

## 10. 結論

この手順書の目的は、ローカルパス依存を避けて、GitHub で管理されている実リポジトリを Nix の入力とする方法を独立した形で説明することです。

実務上は次の流れがよく使われます。

1. まずはローカルソースで動くか確認する
2. 正常に動いたら GitHub 版へ切り替える
3. `rev` を固定して再現性を上げる

この `srsei` はまさにそのパターンであり、GitHub 版でも十分に正常に動作しました。

---

## 11. 運用上のおすすめ

今回のようにソースがほぼ固定である場合は、GitHub 版を採用するのが最も整理しやすいです。

特に次の要件がある場合に有効です。

- 再現性が必要
- 別環境へ展開したい
- 共有設定として残したい
- ルールとして Nix の入力を Git 管理にしたい

ローカルソース版は実験的な導入には向いていますが、正式運用では GitHub 版のほうが管理しやすいです。
