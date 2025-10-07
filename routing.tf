# =============================================================================
# ルーティングテーブル設定
# VPC内のネットワークトラフィック制御とインターネットアクセス管理
# パブリック/プライベートサブネット間の通信フローを定義
# =============================================================================

# =============================================================================
# パブリックサブネット用ルーティングテーブル
# 踏み台サーバー配置用：直接インターネットアクセス可能
# =============================================================================

# パブリックサブネット用ルーティングテーブル
resource "tencentcloud_route_table" "public" {
  vpc_id = tencentcloud_vpc.main.id
  name   = "${var.project_name}-public-rt-${var.environment}"

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-public-rt-${var.environment}"
    ResourceType = "public"
  })
}

# パブリックサブネットのデフォルトルート
# 全ての外部トラフィックを直接インターネットゲートウェイへ転送
resource "tencentcloud_route_table_entry" "public_default" {
  route_table_id         = tencentcloud_route_table.public.id
  destination_cidr_block = "0.0.0.0/0" # 全ての外部アドレス
  next_type              = "EIP"       # 弾性パブリックIP経由
  next_hub               = "0"         # システムデフォルトゲートウェイ
  description            = "パブリックサブネット用デフォルトルート - 直接インターネットアクセス"
}

# パブリックサブネットとルーティングテーブルの関連付け
resource "tencentcloud_route_table_association" "public" {
  count          = length(tencentcloud_subnet.public)
  subnet_id      = tencentcloud_subnet.public[count.index].id
  route_table_id = tencentcloud_route_table.public.id
}

# =============================================================================
# プライベートサブネット用ルーティングテーブル
# Webサーバー配置用：NATゲートウェイ経由でのみ外部アクセス可能
# セキュリティ強化：インバウンド接続は完全に遮断
# =============================================================================

# プライベートサブネット用ルーティングテーブル（AZ別）
resource "tencentcloud_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = tencentcloud_vpc.main.id
  name   = "${var.project_name}-private-rt-${count.index + 1}-${var.environment}"

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-private-rt-${count.index + 1}-${var.environment}"
    ResourceType = "private"
  })
}

# プライベートサブネットのデフォルトルート
# 全ての外部トラフィックをNATゲートウェイ経由で転送（アウトバウンドのみ）
resource "tencentcloud_route_table_entry" "private_default" {
  count                  = length(tencentcloud_route_table.private)
  route_table_id         = tencentcloud_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"                      # 全ての外部アドレス
  next_type              = "NAT"                            # NATゲートウェイ経由
  next_hub               = tencentcloud_nat_gateway.main.id # 共有NATゲートウェイ
  description            = "プライベートサブネット用デフォルトルート - NATゲートウェイ経由外部アクセス"
}

# プライベートサブネットとルーティングテーブルの関連付け
resource "tencentcloud_route_table_association" "private" {
  count          = length(tencentcloud_subnet.private)
  subnet_id      = tencentcloud_subnet.private[count.index].id
  route_table_id = tencentcloud_route_table.private[count.index].id
}

# =============================================================================
# ルーティング設計原則とセキュリティ考慮事項:
# 
# ネットワークセグメンテーション戦略:
# ┌─────────────────────────────────────────────────────────────┐
# │                    インターネット                              │
# └─────────────────┬───────────────────────────────────────────┘
#                   │
#                   ▼
# ┌─────────────────────────────────────────────────────────────┐
# │              パブリックサブネット                              │
# │  ┌─────────────┐    ┌─────────────┐                        │
# │  │踏み台サーバー1│    │踏み台サーバー2│                        │
# │  │10.0.1.11   │    │10.0.2.16   │                        │
# │  └─────────────┘    └─────────────┘                        │
# │         │                   │                              │
# │         └───────┬───────────┘                              │
# └─────────────────┼───────────────────────────────────────────┘
#                   │ SSH管理アクセス
#                   ▼
# ┌─────────────────────────────────────────────────────────────┐
# │             プライベートサブネット                              │
# │  ┌─────────────┐    ┌─────────────┐                        │
# │  │Webサーバー1  │    │Webサーバー2  │                        │
# │  │10.0.10.13  │    │10.0.20.5   │                        │
# │  └─────────────┘    └─────────────┘                        │
# │         │                   │                              │
# │         └───────┬───────────┘                              │
# └─────────────────┼───────────────────────────────────────────┘
#                   │ アウトバウンドのみ
#                   ▼
# ┌─────────────────────────────────────────────────────────────┐
# │                NATゲートウェイ                                │
# │            (43.133.172.230)                               │
# └─────────────────┬───────────────────────────────────────────┘
#                   │
#                   ▼
# ┌─────────────────────────────────────────────────────────────┐
# │                    インターネット                              │
# └─────────────────────────────────────────────────────────────┘
# 
# セキュリティ特性:
# 1. 踏み台サーバー: 双方向インターネット通信（管理アクセス用）
# 2. Webサーバー: アウトバウンドのみ（パッケージ更新、API呼び出し等）
# 3. NATゲートウェイ: ステートフル接続（レスポンスのみ許可）
# 4. 完全なネットワーク分離: プライベートサブネットへの直接アクセス不可
# 
# 高可用性設計:
# - マルチAZ配置による冗長性確保
# - 各AZ独立のルーティングテーブル
# - 単一障害点の排除
# 
# コスト最適化:
# - 共有NATゲートウェイによるコスト削減
# - 必要最小限のルーティングエントリ
# =============================================================================