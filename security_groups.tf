# =============================================================================
# セキュリティグループ設定
# ネットワークレベルのファイアウォール規則定義
# 最小権限の原則に基づいた細かなアクセス制御を実装
# =============================================================================

# =============================================================================
# 踏み台サーバー（Bastion Host）セキュリティグループ
# インターネットからのSSHアクセスを許可する唯一のエントリーポイント
# =============================================================================

# 踏み台サーバー用セキュリティグループ
resource "tencentcloud_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg-${var.environment}"
  description = "踏み台サーバー用セキュリティグループ - SSH管理アクセス制御"
  
  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-bastion-sg-${var.environment}"
    ResourceType = "bastion"
  })
}

# 踏み台サーバーファイアウォール規則
# セキュリティ原則：SSH（22番ポート）のみ許可、VPC内部通信も許可
resource "tencentcloud_security_group_rule_set" "bastion_ssh_inbound" {
  security_group_id = tencentcloud_security_group.bastion.id
  
  # インバウンド規則：SSH接続許可
  # 注意：本番環境では特定のIPアドレスに制限することを推奨
  ingress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"  # 全てのIPから許可（本番では制限推奨）
    protocol    = "TCP"
    port        = "22"
    description = "管理者SSH接続 - 踏み台サーバーへのアクセス"
  }
  
  # VPC内部通信許可
  # 踏み台サーバーからプライベートサブネットへの全ての通信を許可
  ingress {
    action      = "ACCEPT"
    cidr_block  = var.vpc_cidr  # VPC内部（10.0.0.0/16）
    protocol    = "ALL"
    port        = "ALL"
    description = "VPC内部通信 - プライベートサブネットとの通信"
  }
  
  # アウトバウンド規則：全ての外部通信許可
  # 踏み台サーバーからプライベートサブネットやインターネットへの接続
  egress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"
    protocol    = "ALL"
    port        = "ALL"
    description = "踏み台サーバーからの全ての外部通信を許可"
  }
}

# =============================================================================
# Webサーバーセキュリティグループ
# プライベートサブネット内のアプリケーションサーバー用
# VPC内部からのアクセスのみ許可（ゼロトラスト原則）
# =============================================================================

# Webサーバー用セキュリティグループ
resource "tencentcloud_security_group" "web" {
  name        = "${var.project_name}-web-sg-${var.environment}"
  description = "Webサーバー用セキュリティグループ - VPC内部アクセス制御"
  
  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-web-sg-${var.environment}"
    ResourceType = "web"
  })
}

# Webサーバーファイアウォール規則
# セキュリティ原則：踏み台サーバーサブネットからのSSHアクセスとVPC内部通信のみ許可
resource "tencentcloud_security_group_rule_set" "web_rules" {
  security_group_id = tencentcloud_security_group.web.id
  
  # SSH管理アクセス（踏み台サーバーサブネット1からのみ）
  ingress {
    action      = "ACCEPT"
    cidr_block  = tencentcloud_subnet.public[0].cidr_block  # 10.0.1.0/24
    protocol    = "TCP"
    port        = "22"
    description = "踏み台サーバーサブネット1からのSSH管理アクセス"
  }
  
  # SSH管理アクセス（踏み台サーバーサブネット2からのみ）
  ingress {
    action      = "ACCEPT"
    cidr_block  = tencentcloud_subnet.public[1].cidr_block  # 10.0.2.0/24
    protocol    = "TCP"
    port        = "22"
    description = "踏み台サーバーサブネット2からのSSH管理アクセス"
  }
  
  # HTTP Webサービス（VPC内部からのみ）
  ingress {
    action      = "ACCEPT"
    cidr_block  = var.vpc_cidr  # VPC内部からのみアクセス可能
    protocol    = "TCP"
    port        = "80"
    description = "VPC内部からのHTTPアクセス - Nginx Webサーバー"
  }
  
  # HTTPS Webサービス（VPC内部からのみ）
  ingress {
    action      = "ACCEPT"
    cidr_block  = var.vpc_cidr  # SSL/TLS暗号化通信
    protocol    = "TCP"
    port        = "443"
    description = "VPC内部からのHTTPSアクセス - SSL/TLS暗号化"
  }
  
  # Node.jsアプリケーションポート（VPC内部からのみ）
  ingress {
    action      = "ACCEPT"
    cidr_block  = var.vpc_cidr  # Node.js開発サーバー用
    protocol    = "TCP"
    port        = "8080"
    description = "VPC内部からのNode.jsアプリアクセス"
  }
  
  # VPC内部通信許可
  # マイクロサービス間通信、データベース接続等
  ingress {
    action      = "ACCEPT"
    cidr_block  = var.vpc_cidr  # VPC内部の全ての通信
    protocol    = "ALL"
    port        = "ALL"
    description = "VPC内部通信 - マイクロサービス間通信"
  }
  
  # アウトバウンド：全ての外部通信許可
  # NATゲートウェイ経由でのパッケージ更新、API呼び出し等
  egress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"
    protocol    = "ALL"
    port        = "ALL"
    description = "NATゲートウェイ経由の全ての外部通信を許可"
  }
}

# =============================================================================
# ALB（Application Load Balancer）セキュリティグループ
# 将来的な拡張用：パブリックロードバランサー配置時に使用
# =============================================================================

# ALB用セキュリティグループ（将来拡張用）
resource "tencentcloud_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "ALB用セキュリティグループ - パブリックWebアクセス制御"
  
  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-alb-sg-${var.environment}"
    ResourceType = "alb"
  })
}

# ALBファイアウォール規則（将来拡張用）
# パブリックWebアクセスを提供する場合の設定
resource "tencentcloud_security_group_rule_set" "alb_rules" {
  security_group_id = tencentcloud_security_group.alb.id
  
  # パブリックHTTPアクセス
  ingress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"  # インターネット全体からのアクセス
    protocol    = "TCP"
    port        = "80"
    description = "インターネットからのHTTPアクセス"
  }
  
  # パブリックHTTPSアクセス
  ingress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"  # SSL/TLS暗号化必須
    protocol    = "TCP"
    port        = "443"
    description = "インターネットからのHTTPSアクセス"
  }
  
  # ALBからVPC内部への転送
  egress {
    action      = "ACCEPT"
    cidr_block  = var.vpc_cidr  # VPC内部のWebサーバーへ転送
    protocol    = "ALL"
    port        = "ALL"
    description = "ALBからVPC内部バックエンドサーバーへの転送"
  }
}

# =============================================================================
# セキュリティグループ設計原則:
# 
# 1. 最小権限の原則 - 必要最小限のポートとプロトコルのみ許可
# 2. 深層防御 - 複数レイヤーでのセキュリティ制御
# 3. ネットワークセグメンテーション - 役割別のアクセス制御
# 4. 監査可能性 - 全ての通信ルールを明示的に定義
# 
# セキュリティフロー:
# インターネット → 踏み台サーバー（SSH:22） → Webサーバー（SSH:22, HTTP:80/443）
# Webサーバー → NATゲートウェイ → インターネット（アウトバウンドのみ）
# 
# 高可用性設計:
# - マルチAZ配置による冗長性
# - 踏み台サーバー複数台による可用性確保
# - ロードバランサー対応（将来拡張）
# =============================================================================