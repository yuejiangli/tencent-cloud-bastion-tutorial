# =============================================================================
# Terraform変数定義
# インフラストラクチャの設定可能パラメータを定義
# 環境間での設定値の統一管理とカスタマイズを実現
# =============================================================================

# =============================================================================
# 基本プロジェクト設定
# =============================================================================

# プロジェクト名：全リソースの命名プレフィックス
variable "project_name" {
  description = "プロジェクト名 - 全リソースの命名に使用される識別子"
  type        = string
  default     = "bastion"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "プロジェクト名は小文字、数字、ハイフンのみ使用可能で、文字で開始し文字または数字で終了する必要があります。"
  }
}

# 環境識別子：dev/staging/prod等の環境区分
variable "environment" {
  description = "デプロイメント環境 (dev, staging, prod等)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "環境は dev, staging, prod のいずれかである必要があります。"
  }
}

# =============================================================================
# ネットワーク設定
# VPCとサブネットの構成パラメータ
# =============================================================================

# VPC CIDRブロック：プライベートネットワークアドレス範囲
variable "vpc_cidr" {
  description = "VPCのCIDRブロック - プライベートネットワークのアドレス範囲"
  type        = string
  default     = "10.0.0.0/16" # 65,536個のIPアドレス（10.0.0.1 - 10.0.255.254）

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "有効なCIDR形式である必要があります（例：10.0.0.0/16）。"
  }
}

# アベイラビリティゾーン：高可用性のためのマルチAZ配置
variable "availability_zones" {
  description = "使用するアベイラビリティゾーン - 高可用性とフォルトトレラント設計"
  type        = list(string)
  default     = ["ap-tokyo-1", "ap-tokyo-2"] # 東京リージョンの2つのAZ

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "高可用性のため、最低2つのアベイラビリティゾーンが必要です。"
  }
}

# パブリックサブネット設定：踏み台サーバー配置用
variable "public_subnet_cidrs" {
  description = "パブリックサブネットのCIDRブロック - 踏み台サーバー配置用（直接インターネットアクセス可能）"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # 各サブネット254個のIPアドレス

  validation {
    condition     = length(var.public_subnet_cidrs) >= 1 && length(var.public_subnet_cidrs) <= 10
    error_message = "パブリックサブネット数は1から10の間である必要があります。"
  }
}

# プライベートサブネット設定：Webサーバー配置用
variable "private_subnet_cidrs" {
  description = "プライベートサブネットのCIDRブロック - Webサーバー配置用（NATゲートウェイ経由のみ外部アクセス）"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"] # セキュアな内部ネットワーク

  validation {
    condition     = length(var.private_subnet_cidrs) >= 1 && length(var.private_subnet_cidrs) <= 10
    error_message = "プライベートサブネット数は1から10の間である必要があります。"
  }
}

# =============================================================================
# コンピュートリソース設定
# EC2インスタンスの仕様とSSHキー設定
# =============================================================================

# 踏み台サーバーインスタンスタイプ：セキュリティゲートウェイ用
variable "bastion_instance_type" {
  description = "踏み台サーバーのインスタンスタイプ - セキュリティと性能のバランス"
  type        = string
  default     = "S5.MEDIUM4" # 2vCPU, 4GB RAM - 管理作業に適した性能

  validation {
    condition     = can(regex("^S[0-9]+\\.(SMALL|MEDIUM|LARGE|XLARGE)[0-9]*$", var.bastion_instance_type))
    error_message = "有効なTencentCloudインスタンスタイプを指定してください（例：S5.MEDIUM4）。"
  }
}

# Webサーバーインスタンスタイプ：アプリケーション実行用
variable "web_instance_type" {
  description = "Webサーバーのインスタンスタイプ - アプリケーション負荷に応じた性能"
  type        = string
  default     = "S5.MEDIUM4" # 2vCPU, 4GB RAM - 一般的なWeb負荷に対応

  validation {
    condition     = can(regex("^S[0-9]+\\.(SMALL|MEDIUM|LARGE|XLARGE)[0-9]*$", var.web_instance_type))
    error_message = "有効なTencentCloudインスタンスタイプを指定してください（例：S5.MEDIUM4）。"
  }
}

# SSHキーペア名：セキュアなリモートアクセス用
variable "key_pair_name" {
  description = "SSHキーペア名 - 全インスタンスへのセキュアアクセス用"
  type        = string
  default     = "bastion_keypair" # アンダースコア使用（TencentCloud命名規則準拠）

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.key_pair_name))
    error_message = "キーペア名は英数字とアンダースコアのみ使用可能です（ハイフン不可）。"
  }
}

# インスタンスイメージID：OS選択用
variable "instance_image_id" {
  description = "インスタンスで使用するイメージID - Ubuntu 20.04 LTS推奨"
  type        = string
  default     = "img-487zeit5" # Ubuntu 20.04 LTS (ap-tokyo リージョン)

  validation {
    condition     = can(regex("^img-[a-z0-9]+$", var.instance_image_id))
    error_message = "有効なTencentCloudイメージIDを指定してください（例：img-487zeit5）。"
  }
}

# =============================================================================
# セキュリティ設定
# ファイアウォールルールとアクセス制御
# =============================================================================

# SSH許可IPアドレス：管理者アクセス制限
variable "allowed_ssh_cidrs" {
  description = "SSH接続を許可するCIDRブロック - セキュリティ強化のため管理者IPのみ許可推奨"
  type        = list(string)
  default     = ["0.0.0.0/0"] # 注意：本番環境では特定IPに制限することを強く推奨

  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "全てのCIDRブロックが有効な形式である必要があります。"
  }
}

# HTTP許可IPアドレス：Webアクセス制御
variable "allowed_http_cidrs" {
  description = "HTTP/HTTPS接続を許可するCIDRブロック - Webサービスアクセス制御"
  type        = list(string)
  default     = ["0.0.0.0/0"] # パブリックWebサービスの場合は全IP許可

  validation {
    condition = alltrue([
      for cidr in var.allowed_http_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "全てのCIDRブロックが有効な形式である必要があります。"
  }
}

# =============================================================================
# NATゲートウェイ設定
# プライベートサブネットの外部接続制御
# =============================================================================

# NAT帯域幅制限：コスト管理と性能調整
variable "nat_bandwidth" {
  description = "NATゲートウェイの帯域幅制限（Mbps） - コスト管理と性能のバランス"
  type        = number
  default     = 100 # 100Mbps - 一般的なWeb負荷に適した帯域幅

  validation {
    condition     = var.nat_bandwidth >= 10 && var.nat_bandwidth <= 5000
    error_message = "NAT帯域幅は10-5000Mbpsの範囲で設定してください。"
  }
}

# NAT同時接続数制限：リソース管理
variable "nat_max_concurrent" {
  description = "NATゲートウェイの最大同時接続数 - リソース使用量制御"
  type        = number
  default     = 1000000 # 100万接続 - 高負荷対応

  validation {
    condition     = var.nat_max_concurrent >= 10000 && var.nat_max_concurrent <= 10000000
    error_message = "NAT最大同時接続数は10,000-10,000,000の範囲で設定してください。"
  }
}

# =============================================================================
# リソースタグ設定
# 統一的なリソース管理とコスト追跡
# =============================================================================

# 共通タグ：全リソースに適用される統一タグ
variable "common_tags" {
  description = "全リソースに適用される共通タグ - 管理、コスト追跡、ガバナンス用"
  type        = map(string)
  default = {
    created-by = "jaden-hands-on" # 作成者識別
  }

  validation {
    condition = alltrue([
      for key, value in var.common_tags :
      can(regex("^[a-zA-Z0-9\\s\\-_\\.:/=+@]+$", key)) &&
      can(regex("^[a-zA-Z0-9\\s\\-_\\.:/=+@]*$", value))
    ])
    error_message = "タグのキーと値は英数字、スペース、および特定の特殊文字（-_.:=+@/）のみ使用可能です。"
  }
}

# =============================================================================
# 変数設計原則とベストプラクティス:
# 
# 1. セキュリティファースト:
#    - デフォルト値は最小権限の原則に従う
#    - 本番環境では制限的な設定を推奨
#    - 検証ルールによる不正値の防止
# 
# 2. 高可用性設計:
#    - マルチAZ配置の強制
#    - 冗長性確保のための最小リソース数制限
# 
# 3. 運用性重視:
#    - 明確な説明文による設定意図の明示
#    - 環境間での設定統一
#    - タグによる統一的なリソース管理
# 
# 4. コスト最適化:
#    - 適切なデフォルト値による無駄な課金防止
#    - リソースサイズの妥当性検証
# 
# 5. 拡張性確保:
#    - 将来の要件変更に対応可能な柔軟な設計
#    - 環境固有の設定オーバーライド対応
# =============================================================================