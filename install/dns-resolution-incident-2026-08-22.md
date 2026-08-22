# DNS 名前解決トラブル記録（2026-08-22）

## 概要
- 対象: dev01, dev02
- 症状: 内部名（例: mint223）が解決できない。検証途中では外部名も解決不能になる状態が発生。
- 最終状態: `/etc/resolv.conf` を NixOS 設定で明示生成し、`nameserver 192.168.0.24` を固定して復旧。

## 何が起きていたか（原因）

### 1. 解決経路の差分
- 比較対象の別環境（NixOS-nixos）は `systemd-resolved` を使わず、`/etc/resolv.conf` が直接 `192.168.0.24` を指す構成だった。
- 一方で dev01 側は一時的に `systemd-resolved` の stub（`127.0.0.53`）経由になっていた。
- 同じ nameserver を指定していても、
  - クライアントリゾルバ実装（glibc + nss）
  - resolved のポリシー
  - single-label 名（例: mint223）の扱い
  が一致しないと挙動差が出る。

### 2. 設定変更の副作用
- 途中で `resolvconf` 生成に依存した時点で、`/etc/resolv.conf` から nameserver 行が欠落した状態が発生。
- その結果、内部名だけでなく外部名も解決不能になった。

## 今回の修正方針

### 方針
- dev01/dev02 は「192.168.0.24 を唯一の参照先」とする。
- DNS 解決経路を単純化し、実績のある環境と同じ方式に合わせる。
- 動的生成への依存を減らすため、`/etc/resolv.conf` を NixOS で明示生成する。

### 実装内容
- `modules/networking.nix` で dev01/dev02 の `nameservers` を以下に固定。
  - `192.168.0.24`
- `systemd-resolved` を無効化。
- `environment.etc."resolv.conf".text` で以下を生成。
  - `options edns0`
  - `nameserver 192.168.0.24`

### 結果
- `cat /etc/resolv.conf` で nameserver 行が復活。
- `ping mint223` 成功。
- `ping google.com` 成功。

## 再発時の確認手順（チェックリスト）
1. `cat /etc/resolv.conf`
- `nameserver` 行が存在するか。
- 期待するサーバ（今回は `192.168.0.24`）か。

2. 直接問い合わせ
- `dig @192.168.0.24 mint223`
- `dig @192.168.0.24 google.com`

3. クライアント側確認
- `getent hosts mint223`
- `ping mint223`

4. resolver 実装確認
- `systemctl status systemd-resolved`
- `resolvectl status`（resolved 使用時のみ）

## 質問への回答: こういうケースで dnsmasq はまずいか？
結論: まずくない。むしろ LAN 内の名前解決を集約する用途として妥当。

ただし、次の点を揃えないと今回のような差分トラブルが起きやすい。

### 運用上の推奨
- クライアントの resolver 実装を混在させない。
  - 例: 全ホストで resolved を使う、または全ホストで直接 resolv.conf を使う。
- single-label 名（mint223 など）に依存しすぎない。
  - 可能なら内部ドメイン付き FQDN（例: mint223.lan）を使う。
- dnsmasq 側で意図したゾーン定義を明示する。
  - `address=` / `host-record=` / `expand-hosts` / `domain=` 等を用途に応じて整備。
- フォールバック方針を明文化する。
  - 「止まったら解決不能でよい」なら単一 nameserver 固定でよい。
  - 可用性重視ならセカンダリ DNS を別系統で用意する。

## 将来の設計オプション

### A. 現状維持（今回の方式）
- 長所: 挙動が単純でトラブルシュートしやすい。
- 短所: `/etc/resolv.conf` を明示管理するため柔軟性は低い。

### B. systemd-resolved に統一
- 長所: DNSSEC/DoT など拡張運用に乗せやすい。
- 短所: 設定層が増え、single-label 名の挙動差を理解して揃える必要がある。

### C. FQDN 運用へ移行
- 長所: 実装差の影響を受けにくく、将来移行が楽。
- 短所: 既存の短縮名運用を置き換える手間がある。

## このリポジトリでの当面の推奨
- まずは今回の構成を維持し、dev01/dev02 の安定動作を優先。
- 次段階で、内部名を FQDN 併記運用にする（短縮名 + FQDN）。
- 余裕がある時に resolver 実装統一（resolved 採用 or 非採用）を検討する。
