# 🏗️ TencentCloud 踏み台サーバーアーキテクチャ

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?style=flat&logo=terraform)](https://www.terraform.io/)
[![TencentCloud](https://img.shields.io/badge/TencentCloud-Tokyo-00A1EA?style=flat&logo=tencentqq)](https://cloud.tencent.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

> **TencentCloud エンタープライズグレードセキュアネットワークアーキテクチャ**

## 🌍 言語選択

- **🇺🇸 [English](../README.md)**
- **🇨🇳 [中文文档](README-zh.md)**
- **🇯🇵 [日本語ドキュメント](README-ja.md)** (現在)

---

## 🎯 プロジェクトハイライト

- 🔒 **本番レベルセキュリティ**: 踏み台サーバー、セキュリティグループ、ネットワーク分離による多層防御
- 🌐 **マルチAZ高可用性**: 複数のアベイラビリティゾーンにリソースを分散配置
- 🚀 **ワンクリックデプロイ**: Terraformによる自動化されたインフラストラクチャプロビジョニング
- 📊 **コスト最適化**: 適切なサイズのインスタンスと詳細なコスト見積もり
- 🛠️ **DevOps対応**: 監視とメンテナンスツールを含む
- 📚 **包括的ドキュメント**: 多言語サポートと詳細ガイド

---

## 🏛️ アーキテクチャ概要

```
インターネットゲートウェイ
         |
   パブリックサブネット (マルチAZ)
    /              \
踏み台サーバー    NATゲートウェイ
    |                 |
    |         プライベートサブネット (マルチAZ)
    |                 |
    └─────────► Webサーバー
```

### 🔐 セキュリティ階層

| 階層 | コンポーネント | 保護機能 |
|------|---------------|----------|
| **ネットワーク** | VPC分離 | プライベートサブネットは直接インターネットアクセス不可 |
| **アクセス** | 踏み台サーバー | 集中化されたSSHアクセス制御とログ記録 |
| **ファイアウォール** | セキュリティグループ | 詳細なポートとプロトコル制限 |
| **認証** | SSH鍵 | 公開鍵認証、パスワード認証無効 |

---

## 🚀 クイックスタート

### 前提条件

- **Terraform** >= 1.0 ([インストールガイド](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- **TencentCloudアカウント** APIアクセス付き
- **SSHクライアント** (OpenSSH推奨)

### デプロイ手順

```bash
# 1. リポジトリクローン
git clone https://github.com/yuejiangli/tencent-cloud-bastion-tutorial.git
cd tencent-cloud-bastion-tutorial

# 2. 認証情報設定 (いずれかの方法を選択)
# 方法A: 環境変数 (推奨)
export TENCENTCLOUD_SECRET_ID="your-secret-id"
export TENCENTCLOUD_SECRET_KEY="your-secret-key"

# 方法B: 認証情報ファイル
mkdir -p ~/.tencentcloud
echo 'secret_id = "your-secret-id"' > ~/.tencentcloud/credentials
echo 'secret_key = "your-secret-key"' >> ~/.tencentcloud/credentials

# 3. インフラストラクチャデプロイ
make init      # Terraform初期化
make plan      # デプロイプラン確認
make apply     # インフラストラクチャデプロイ (約10分)
```

---

## 📦 インフラストラクチャコンポーネント

### 🌐 ネットワークリソース

| リソース | 数量 | 仕様 | 用途 |
|----------|------|------|------|
| **VPC** | 1 | 10.0.0.0/16 | メインネットワークコンテナ |
| **パブリックサブネット** | 2 | 10.0.1.0/24, 10.0.2.0/24 | 踏み台サーバー、NATゲートウェイ |
| **プライベートサブネット** | 2 | 10.0.10.0/24, 10.0.20.0/24 | Webサーバー |
| **インターネットゲートウェイ** | 1 | 自動管理 | パブリックインターネットアクセス |
| **NATゲートウェイ** | 1 | 100Mbps帯域幅 | プライベートサブネットアウトバウンド |

### 💻 コンピュートリソース

| リソース | 数量 | インスタンスタイプ | vCPU | メモリ | 月額費用* |
|----------|------|-------------------|------|--------|-----------|
| **踏み台サーバー** | 2 | S5.MEDIUM4 | 2 | 4GB | ~$60 |
| **Webサーバー** | 2 | S5.MEDIUM4 | 2 | 4GB | ~$60 |
| **NATゲートウェイ** | 1 | スタンダード | - | - | ~$45 |
| **EIP** | 3 | スタンダード | - | - | ~$15 |
| | | | | **合計** | **~$180** |

*東京リージョン推定費用

---

## 🎮 使用ガイド

### 🔑 SSHアクセス

```bash
# 1. 踏み台サーバー接続
ssh -i ~/.ssh/bastion_keypair.pem ubuntu@<踏み台サーバーパブリックIP>

# 2. 踏み台サーバー経由でWebサーバー接続 (ジャンプホスト)
ssh -i ~/.ssh/bastion_keypair.pem -J ubuntu@<踏み台サーバーIP> ubuntu@<WebサーバープライベートIP>

# 3. SSHエージェントフォワーディング (推奨)
ssh-add ~/.ssh/bastion_keypair.pem
ssh -A ubuntu@<踏み台サーバーIP>
# 踏み台サーバーから:
ssh ubuntu@<WebサーバープライベートIP>

# 4. Webサービスアクセス用ポートフォワーディング
ssh -i ~/.ssh/bastion_keypair.pem -L 8080:<WebサーバープライベートIP>:80 ubuntu@<踏み台サーバーIP>
# ブラウザでアクセス: http://localhost:8080
```

### 🛠️ 管理コマンド

```bash
# インフラストラクチャ管理
make plan              # 変更プレビュー
make apply             # 変更適用
make destroy           # インフラストラクチャ破棄
make refresh           # 状態更新

# 監視・メンテナンス
make status            # リソース状態確認
make logs              # デプロイログ表示
make validate          # 設定検証
make format            # Terraformファイル整形

# デプロイ情報取得
terraform output       # 全出力表示
terraform output bastion_public_ips    # 踏み台サーバーIP表示
terraform output web_private_ips       # WebサーバーIP表示
```

---

## 🔧 カスタマイズ

### 設定オプション

`terraform.tfvars.example` をコピーして変更:

```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集して設定を変更
```

主要設定オプション:

```hcl
# 基本設定
project_name = "my-bastion-project"
environment  = "production"

# インスタンス設定
bastion_instance_type = "S5.LARGE8"    # 高性能にアップグレード
web_instance_type     = "S5.LARGE8"    # 高性能にアップグレード
instance_count        = 3              # Webサーバー数スケールアップ

# ネットワーク設定
vpc_cidr = "10.0.0.0/16"
allowed_ssh_cidrs = ["203.0.113.0/24"] # SSHアクセス制限
```

---

## 🛡️ セキュリティベストプラクティス

### ✅ 実装済みセキュリティ対策

- [x] **ネットワークセグメンテーション**: プライベートサブネットはインターネットから分離
- [x] **踏み台サーバーアクセス**: 集中化されたSSHアクセス制御
- [x] **セキュリティグループ**: 最小権限ファイアウォールルール
- [x] **SSH鍵認証**: パスワード認証無効
- [x] **暗号化ストレージ**: EBSボリューム保存時暗号化

### 🔍 セキュリティチェックリスト

本番デプロイ前:

- [ ] セキュリティグループルールの確認とカスタマイズ
- [ ] SSH鍵ローテーションポリシーの実装
- [ ] 監視とアラートの設定
- [ ] バックアップ手順の設定
- [ ] セキュリティテストの実施

---

## 🐛 トラブルシューティング

### よくある問題

**SSH接続失敗**
```bash
# セキュリティグループルール確認
terraform state show tencentcloud_security_group.bastion

# SSH鍵権限確認
chmod 600 ~/.ssh/bastion_keypair.pem

# 接続性テスト
telnet <踏み台サーバーIP> 22
```

**Webサーバーがインターネットにアクセスできない**
```bash
# NATゲートウェイ状態確認
terraform state show tencentcloud_nat_gateway.main

# ルートテーブル設定確認
terraform state show tencentcloud_route_table.private
```

**認証エラー**
```bash
# 認証情報設定確認
echo $TENCENTCLOUD_SECRET_ID
echo $TENCENTCLOUD_SECRET_KEY

# または認証情報ファイル確認
cat ~/.tencentcloud/credentials
```

---

## 💰 コスト最適化

### コスト削減戦略

```bash
# 開発環境で小さなインスタンス使用
terraform apply -var="bastion_instance_type=S5.SMALL2"
terraform apply -var="web_instance_type=S5.SMALL2"

# スポットインスタンス有効化 (70%コスト削減)
terraform apply -var="enable_spot_instances=true"

# テスト用スケールダウン
terraform apply -var="instance_count=1"
```

### 月額コスト内訳

- **開発環境**: ~$80/月 (小さなインスタンス)
- **本番環境**: ~$180/月 (現在の設定)
- **高性能環境**: ~$300/月 (大きなインスタンス)

---

## 📚 ドキュメント

### ファイル構造

```
├── main.tf                    # メインTerraform設定
├── variables.tf               # 変数定義
├── outputs.tf                 # 出力定義
├── versions.tf                # プロバイダーバージョン
├── compute.tf                 # EC2インスタンスとキーペア
├── network.tf                 # VPC、サブネット、ゲートウェイ
├── security.tf                # セキュリティグループとルール
├── scripts/
│   ├── bastion_userdata.sh    # 踏み台サーバー初期化スクリプト
│   └── web_userdata.sh        # Webサーバー初期化スクリプト
├── terraform.tfvars.example   # 設定例
├── Makefile                   # 自動化コマンド
├── DEPLOYMENT_CHECKLIST.md    # デプロイチェックリスト
└── docs/
    ├── README-zh.md           # 中国語ドキュメント
    └── README-ja.md           # 日本語ドキュメント
```

### 追加リソース

- [Terraform TencentCloudプロバイダー](https://registry.terraform.io/providers/tencentcloudstack/tencentcloud/latest/docs)
- [TencentCloud VPCドキュメント](https://cloud.tencent.com/document/product/215)
- [ネットワークセキュリティベストプラクティス](https://cloud.tencent.com/document/product/215/20046)

---

## 🤝 コントリビューション

コントリビューション歓迎！お気軽にPull Requestを提出してください。

### 開発セットアップ

```bash
# リポジトリクローン
git clone https://github.com/yuejiangli/tencent-cloud-bastion-tutorial.git

# pre-commitフック インストール
pre-commit install

# テスト実行
make test
```

---

## 📄 ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細は [LICENSE](../LICENSE) ファイルを参照してください。

---

## 🙏 謝辞

- [HashiCorp Terraform](https://www.terraform.io/) Infrastructure as Codeの提供
- [TencentCloud](https://cloud.tencent.com/) 信頼性の高いクラウドインフラストラクチャの提供
- 改善とフィードバックをいただいたコミュニティコントリビューター

---

<div align="center">

**⭐ このプロジェクトが役に立ったら、ぜひスターをお願いします！ ⭐**

[![GitHub stars](https://img.shields.io/github/stars/yuejiangli/tencent-cloud-bastion-tutorial?style=social)](https://github.com/yuejiangli/tencent-cloud-bastion-tutorial/stargazers)

**DevOpsコミュニティのために ❤️ で作成**

</div>