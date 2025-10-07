# 腾讯云 VPC 网络架构 - Terraform 部署
# TencentCloud VPC ネットワークアーキテクチャ - Terraform デプロイメント
# TencentCloud VPC Network Architecture - Terraform Deployment

[中文](#中文) | [日本語](#日本語) | [English](#english)

---

## 中文

### 🏗️ 项目概述

这是一套完整的 Terraform 配置，用于在腾讯云东京地域部署安全、高可用的 VPC 网络架构，包含踏み台サーバー（堡垒机）和 Web 服务器。

### 📐 架构图

```
Internet (互联网)
    |
    ├─ Internet Gateway (互联网网关)
    |
    ├─ Public Subnet (公有子网: 10.0.1.0/24, 10.0.2.0/24)
    │   └─ Bastion Hosts (踏み台サーバー)
    │       ├─ EIP (弹性公网IP)
    │       └─ Security Group (安全组: SSH 22端口)
    |
    ├─ NAT Gateway (NAT网关)
    │   └─ EIP (私有子网出网IP)
    |
    └─ Private Subnet (私有子网: 10.0.10.0/24, 10.0.20.0/24)
        └─ Web Servers (Web服务器)
            ├─ No Public IP (无公网IP)
            ├─ Security Group (安全组: HTTP 80, HTTPS 443, SSH 22)
            └─ Internet Access via NAT Gateway (通过NAT网关访问互联网)
```

### 🚀 快速开始

#### 方式一：使用 Dev Container（推荐）

🐳 **一键启动完整开发环境，无需本地安装任何工具！**

**前置要求：**
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers 扩展](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

**启动步骤：**
```bash
# 1. 运行快速设置脚本
chmod +x dev-setup.sh
./dev-setup.sh

# 2. 选择 "1. 使用 Dev Container (推荐)"
# 3. 输入腾讯云 API 凭证
# 4. VS Code 将自动打开并提示使用容器环境
```

#### 方式二：本地环境

```bash
# 1. 安装 Terraform
brew install terraform  # macOS
# 或参考官方文档安装

# 2. 配置腾讯云凭证
export TENCENTCLOUD_SECRET_ID="your-secret-id"
export TENCENTCLOUD_SECRET_KEY="your-secret-key"

# 3. 生成 SSH 密钥
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# 4. 部署基础设施
terraform init
terraform plan
terraform apply
```

### 📋 部署的资源

**网络资源：**
- VPC (10.0.0.0/16)
- 公有子网 × 2（跨可用区）
- 私有子网 × 2（跨可用区）
- NAT 网关 + 弹性公网IP

**计算资源：**
- 踏み台サーバー × 2台（S5.MEDIUM4）
- Web 服务器 × 2台（S5.MEDIUM4）
- SSH 密钥对

**安全资源：**
- 安全组（踏み台サーバー、Web服务器、ALB）
- 网络ACL和路由表

### 🔐 安全特性

- **网络隔离**：私有子网无公网访问
- **跳板访问**：通过踏み台サーバー统一管理
- **最小权限**：精确的安全组规则
- **SSH密钥认证**：禁用密码登录

### 🔧 使用指南

```bash
# 连接踏み台サーバー
ssh -i ~/.ssh/bastion_keypair.pem ubuntu@<bastion-public-ip>

# 通过踏み台サーバー访问Web服务器
ssh -A -J ubuntu@<bastion-ip> ubuntu@<web-private-ip>

# 查看部署信息
terraform output
```

---

## 日本語

### 🏗️ プロジェクト概要

これは、TencentCloud東京リージョンにセキュアで高可用性のVPCネットワークアーキテクチャをデプロイするための完全なTerraform設定です。踏み台サーバー（Bastion Host）とWebサーバーが含まれています。

### 📐 アーキテクチャ図

```
インターネット
    |
    ├─ インターネットゲートウェイ
    |
    ├─ パブリックサブネット (10.0.1.0/24, 10.0.2.0/24)
    │   └─ 踏み台サーバー (Bastion Hosts)
    │       ├─ EIP (パブリックIPアドレス)
    │       └─ セキュリティグループ (SSH: 22番ポート)
    |
    ├─ NATゲートウェイ
    │   └─ EIP (プライベートサブネット用外部接続)
    |
    └─ プライベートサブネット (10.0.10.0/24, 10.0.20.0/24)
        └─ Webサーバー
            ├─ パブリックIPなし
            ├─ セキュリティグループ (HTTP: 80, HTTPS: 443, SSH: 22)
            └─ NATゲートウェイ経由インターネットアクセス
```

### 🚀 クイックスタート

#### 方法1：Dev Container使用（推奨）

🐳 **ワンクリックで完全な開発環境を起動、ローカルツールのインストール不要！**

**前提条件：**
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

**起動手順：**
```bash
# 1. クイックセットアップスクリプト実行
chmod +x dev-setup.sh
./dev-setup.sh

# 2. "1. Dev Container使用（推奨）"を選択
# 3. TencentCloud API認証情報を入力
# 4. VS Codeが自動的に開き、コンテナ環境の使用を促す
```

#### 方法2：ローカル環境

```bash
# 1. Terraformインストール
brew install terraform  # macOS
# または公式ドキュメントを参照

# 2. TencentCloud認証情報設定
export TENCENTCLOUD_SECRET_ID="your-secret-id"
export TENCENTCLOUD_SECRET_KEY="your-secret-key"

# 3. SSH鍵生成
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# 4. インフラストラクチャデプロイ
terraform init
terraform plan
terraform apply
```

### 📋 デプロイされるリソース

**ネットワークリソース：**
- VPC (10.0.0.0/16)
- パブリックサブネット × 2（マルチAZ）
- プライベートサブネット × 2（マルチAZ）
- NATゲートウェイ + EIP

**コンピュートリソース：**
- 踏み台サーバー × 2台（S5.MEDIUM4）
- Webサーバー × 2台（S5.MEDIUM4）
- SSH鍵ペア

**セキュリティリソース：**
- セキュリティグループ（踏み台サーバー、Webサーバー、ALB）
- ネットワークACLとルーティングテーブル

### 🔐 セキュリティ機能

- **ネットワーク分離**：プライベートサブネットはパブリックアクセス不可
- **踏み台アクセス**：踏み台サーバー経由の統一管理
- **最小権限の原則**：精密なセキュリティグループルール
- **SSH鍵認証**：パスワードログイン無効化

### 🔧 使用ガイド

```bash
# 踏み台サーバー接続
ssh -i ~/.ssh/bastion_keypair.pem ubuntu@<bastion-public-ip>

# 踏み台サーバー経由でWebサーバーアクセス
ssh -A -J ubuntu@<bastion-ip> ubuntu@<web-private-ip>

# デプロイ情報確認
terraform output
```

---

## English

### 🏗️ Project Overview

This is a complete Terraform configuration for deploying a secure, highly available VPC network architecture in TencentCloud Tokyo region, including Bastion Hosts and Web Servers.

### 📐 Architecture Diagram

```
Internet
    |
    ├─ Internet Gateway
    |
    ├─ Public Subnet (10.0.1.0/24, 10.0.2.0/24)
    │   └─ Bastion Hosts
    │       ├─ EIP (Elastic IP)
    │       └─ Security Group (SSH: Port 22)
    |
    ├─ NAT Gateway
    │   └─ EIP (Private Subnet Outbound)
    |
    └─ Private Subnet (10.0.10.0/24, 10.0.20.0/24)
        └─ Web Servers
            ├─ No Public IP
            ├─ Security Group (HTTP: 80, HTTPS: 443, SSH: 22)
            └─ Internet Access via NAT Gateway
```

### 🚀 Quick Start

#### Option 1: Using Dev Container (Recommended)

🐳 **One-click complete development environment, no local tool installation required!**

**Prerequisites:**
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

**Setup Steps:**
```bash
# 1. Run quick setup script
chmod +x dev-setup.sh
./dev-setup.sh

# 2. Select "1. Use Dev Container (Recommended)"
# 3. Enter TencentCloud API credentials
# 4. VS Code will open automatically and prompt to use container
```

#### Option 2: Local Environment

```bash
# 1. Install Terraform
brew install terraform  # macOS
# Or refer to official documentation

# 2. Configure TencentCloud credentials
export TENCENTCLOUD_SECRET_ID="your-secret-id"
export TENCENTCLOUD_SECRET_KEY="your-secret-key"

# 3. Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# 4. Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### 📋 Deployed Resources

**Network Resources:**
- VPC (10.0.0.0/16)
- Public Subnets × 2 (Multi-AZ)
- Private Subnets × 2 (Multi-AZ)
- NAT Gateway + EIP

**Compute Resources:**
- Bastion Hosts × 2 (S5.MEDIUM4)
- Web Servers × 2 (S5.MEDIUM4)
- SSH Key Pair

**Security Resources:**
- Security Groups (Bastion, Web Server, ALB)
- Network ACLs and Route Tables

### 🔐 Security Features

- **Network Isolation**: Private subnets have no public access
- **Bastion Access**: Centralized management through bastion hosts
- **Least Privilege**: Precise security group rules
- **SSH Key Authentication**: Password login disabled

### 🔧 Usage Guide

```bash
# Connect to Bastion Host
ssh -i ~/.ssh/bastion_keypair.pem ubuntu@<bastion-public-ip>

# Access Web Server through Bastion Host
ssh -A -J ubuntu@<bastion-ip> ubuntu@<web-private-ip>

# View deployment information
terraform output
```

---

## 📚 共通リソース / Common Resources / 通用资源

### 🛠️ 利用可能なMakeコマンド / Available Make Commands / 可用的Make命令

```bash
make help              # ヘルプ表示 / Show help / 显示帮助
make check             # 設定検証 / Validate configuration / 验证配置
make quick-deploy      # クイックデプロイ / Quick deployment / 快速部署
make security-scan     # セキュリティスキャン / Security scan / 安全扫描
make cost-estimate     # コスト見積もり / Cost estimation / 成本估算
make docs              # ドキュメント生成 / Generate docs / 生成文档
make clean             # リソース削除 / Clean resources / 清理资源
```

### 📁 ファイル構造 / File Structure / 文件结构

```
bastion_test/
├── README.md                    # このファイル / This file / 本文件
├── dev-setup.sh                 # 開発環境セットアップ / Dev setup / 开发环境设置
├── Makefile                     # 自動化コマンド / Automation / 自动化命令
├── .devcontainer/               # Dev Container設定 / Dev Container config / Dev Container配置
├── scripts/                     # 初期化スクリプト / Init scripts / 初始化脚本
│   ├── bastion_userdata.sh     # 踏み台サーバー初期化 / Bastion init / 堡垒机初始化
│   └── web_userdata.sh         # Webサーバー初期化 / Web server init / Web服务器初始化
├── versions.tf                  # プロバイダー設定 / Provider config / 提供商配置
├── variables.tf                 # 変数定義 / Variable definitions / 变量定义
├── vpc.tf                      # VPC設定 / VPC configuration / VPC配置
├── routing.tf                  # ルーティング設定 / Routing config / 路由配置
├── security_groups.tf          # セキュリティグループ / Security groups / 安全组
├── compute.tf                  # コンピュートリソース / Compute resources / 计算资源
├── outputs.tf                  # 出力値 / Output values / 输出值
├── terraform.tfvars            # 設定値 / Configuration values / 配置值
└── terraform.tfvars.example    # 設定例 / Configuration example / 配置示例
```

### 🔧 トラブルシューティング / Troubleshooting / 故障排除

**よくある問題 / Common Issues / 常见问题：**

1. **SSH接続失敗 / SSH Connection Failed / SSH连接失败**
   ```bash
   # セキュリティグループ確認 / Check security groups / 检查安全组
   terraform state show tencentcloud_security_group.bastion
   
   # SSH鍵確認 / Verify SSH key / 验证SSH密钥
   ls -la ~/.ssh/bastion_keypair.pem
   chmod 600 ~/.ssh/bastion_keypair.pem
   ```

2. **インターネットアクセス不可 / No Internet Access / 无法访问互联网**
   ```bash
   # NATゲートウェイ状態確認 / Check NAT Gateway / 检查NAT网关
   terraform state show tencentcloud_nat_gateway.main
   
   # ルーティング確認 / Check routing / 检查路由
   terraform state show tencentcloud_route_table.private
   ```

### 📞 サポート / Support / 支持

- **Issues**: GitHub Issues でバグ報告や機能要求 / Report bugs or request features / 报告错误或请求功能
- **Discussions**: 質問や議論 / Questions and discussions / 问题和讨论
- **Documentation**: 詳細ドキュメント / Detailed documentation / 详细文档

### 📄 ライセンス / License / 许可证

MIT License - 詳細は LICENSE ファイルを参照 / See LICENSE file for details / 详见LICENSE文件

---

**⚠️ 注意 / Notice / 注意**: これは本番レベルの設定です。デプロイ前にすべてのセキュリティ設定を慎重に確認してください。/ This is production-level configuration. Please carefully review all security settings before deployment. / 这是生产级配置，部署前请仔细审查所有安全设置。