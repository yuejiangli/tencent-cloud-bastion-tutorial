# =============================================================================
# VPC（Virtual Private Cloud）ネットワーク設定
# 踏み台サーバー（Bastion Host）とWebサーバーのためのセキュアなネットワーク環境を構築
# =============================================================================

# メインVPC設定
# プライベートクラウド環境の基盤となるネットワーク
resource "tencentcloud_vpc" "main" {
  name       = "${var.project_name}-vpc-${var.environment}"
  cidr_block = var.vpc_cidr # デフォルト: 10.0.0.0/16

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-vpc-${var.environment}"
  })
}

# パブリックサブネット設定
# インターネットゲートウェイ経由で直接インターネットアクセス可能
# 踏み台サーバー（Bastion Host）を配置するためのサブネット
resource "tencentcloud_subnet" "public" {
  count = length(var.public_subnet_cidrs) # 複数AZ対応（高可用性）

  name              = "${var.project_name}-public-subnet-${count.index + 1}-${var.environment}"
  vpc_id            = tencentcloud_vpc.main.id
  availability_zone = var.availability_zones[count.index]  # マルチAZ配置
  cidr_block        = var.public_subnet_cidrs[count.index] # 10.0.1.0/24, 10.0.2.0/24
  is_multicast      = false

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-public-subnet-${count.index + 1}-${var.environment}"
    ResourceType = "public"
  })
}

# プライベートサブネット設定
# インターネットから直接アクセス不可、NATゲートウェイ経由でのみ外部通信
# Webサーバーなどのアプリケーションサーバーを配置
resource "tencentcloud_subnet" "private" {
  count = length(var.private_subnet_cidrs) # 複数AZ対応（高可用性）

  name              = "${var.project_name}-private-subnet-${count.index + 1}-${var.environment}"
  vpc_id            = tencentcloud_vpc.main.id
  availability_zone = var.availability_zones[count.index]   # マルチAZ配置
  cidr_block        = var.private_subnet_cidrs[count.index] # 10.0.10.0/24, 10.0.20.0/24
  is_multicast      = false

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-private-subnet-${count.index + 1}-${var.environment}"
    ResourceType = "private"
  })
}

# 重要：Tencent Cloud VPCはデフォルトでインターネットゲートウェイ機能を含む
# パブリックサブネットはデフォルトルートテーブル経由で自動的にインターネットアクセス可能

# =============================================================================
# NATゲートウェイ設定
# プライベートサブネット内のリソースがインターネットにアクセスするための仕組み
# =============================================================================

# NATゲートウェイ本体
# プライベートサブネットからのアウトバウンド通信を可能にする
# セキュリティ：インバウンド接続は一切許可しない（一方向通信のみ）
resource "tencentcloud_nat_gateway" "main" {
  name             = "${var.project_name}-nat-gateway-${var.environment}"
  vpc_id           = tencentcloud_vpc.main.id         # VPCレベルのリソース
  bandwidth        = 100                              # 帯域幅: 100Mbps
  max_concurrent   = 1000000                          # 最大同時接続数: 100万
  assigned_eip_set = [tencentcloud_eip.nat.public_ip] # 専用EIP割り当て

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-nat-gateway-${var.environment}"
  })
}

# NATゲートウェイ専用EIP（Elastic IP）
# プライベートサブネットからの外部通信時のソースIPアドレス
# 踏み台サーバーのEIPとは完全に分離された独立リソース
resource "tencentcloud_eip" "nat" {
  name                       = "${var.project_name}-nat-eip-${var.environment}"
  internet_charge_type       = "TRAFFIC_POSTPAID_BY_HOUR" # トラフィック従量課金
  internet_max_bandwidth_out = 100                        # アウトバウンド帯域幅: 100Mbps

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-nat-eip-${var.environment}"
    ResourceType = "nat-gateway"
  })
}

# =============================================================================
# ネットワークアーキテクチャ概要:
# 
# インターネット
#     ↓
# 踏み台サーバー（パブリックサブネット）← 管理者アクセス用エントリーポイント
#     ↓ SSH踏み台
# Webサーバー（プライベートサブネット）← アプリケーション実行環境
#     ↓ アウトバウンド通信のみ
# NATゲートウェイ → インターネット
# 
# セキュリティ特徴:
# - 多層防御アーキテクチャ
# - 最小権限の原則
# - ネットワークセグメンテーション
# - 監査可能なアクセス制御
# =============================================================================