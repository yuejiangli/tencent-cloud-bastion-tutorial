# =============================================================================
# Terraform出力値定義
# デプロイ完了後の重要な情報を外部に公開
# 運用管理とトラブルシューティングに必要な情報を提供
# =============================================================================

# =============================================================================
# ネットワーク情報出力
# VPCとサブネットの基本情報
# =============================================================================

# VPC基本情報：ネットワーク全体の識別情報
output "vpc_info" {
  description = "VPC基本情報 - ネットワーク全体の構成"
  value = {
    vpc_id   = tencentcloud_vpc.main.id
    vpc_name = tencentcloud_vpc.main.name
    vpc_cidr = tencentcloud_vpc.main.cidr_block
  }
}

# パブリックサブネット情報：踏み台サーバー配置先
output "public_subnets" {
  description = "パブリックサブネット情報 - 踏み台サーバー配置先ネットワーク"
  value = {
    for idx, subnet in tencentcloud_subnet.public :
    "az_${idx + 1}" => {
      subnet_id   = subnet.id
      subnet_name = subnet.name
      cidr_block  = subnet.cidr_block
      az          = subnet.availability_zone
    }
  }
}

# プライベートサブネット情報：Webサーバー配置先
output "private_subnets" {
  description = "プライベートサブネット情報 - Webサーバー配置先ネットワーク"
  value = {
    for idx, subnet in tencentcloud_subnet.private :
    "az_${idx + 1}" => {
      subnet_id   = subnet.id
      subnet_name = subnet.name
      cidr_block  = subnet.cidr_block
      az          = subnet.availability_zone
    }
  }
}

# =============================================================================
# 踏み台サーバー情報出力
# セキュリティゲートウェイアクセス情報
# =============================================================================

# 踏み台サーバー接続情報：SSH管理アクセス用
output "bastion_hosts" {
  description = "踏み台サーバー接続情報 - SSH管理アクセス用エンドポイント"
  value = {
    for idx, instance in tencentcloud_instance.bastion :
    "bastion_${idx + 1}" => {
      instance_id   = instance.id
      instance_name = instance.instance_name
      public_ip     = instance.public_ip
      private_ip    = instance.private_ip
      az            = instance.availability_zone
      ssh_command   = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${instance.public_ip}"
    }
  }
}

# 踏み台サーバー管理情報：運用監視用
output "bastion_management" {
  description = "踏み台サーバー管理情報 - 運用監視とトラブルシューティング用"
  value = {
    instance_type   = var.bastion_instance_type
    security_groups = [tencentcloud_security_group.bastion.id]
    key_pair_name   = var.key_pair_name
    total_instances = length(tencentcloud_instance.bastion)
  }
}

# =============================================================================
# Webサーバー情報出力
# アプリケーションサーバー接続情報
# =============================================================================

# Webサーバー接続情報：内部アクセス用
output "web_servers" {
  description = "Webサーバー接続情報 - 踏み台サーバー経由アクセス用"
  value = {
    for idx, instance in tencentcloud_instance.web :
    "web_${idx + 1}" => {
      instance_id   = instance.id
      instance_name = instance.instance_name
      private_ip    = instance.private_ip
      az            = instance.availability_zone
      ssh_command   = "ssh -A -J ubuntu@${tencentcloud_instance.bastion[0].public_ip} ubuntu@${instance.private_ip}"
      http_url      = "http://${instance.private_ip}"
    }
  }
}

# Webサーバー管理情報：運用監視用
output "web_management" {
  description = "Webサーバー管理情報 - 運用監視とスケーリング用"
  value = {
    instance_type   = var.web_instance_type
    security_groups = [tencentcloud_security_group.web.id]
    total_instances = length(tencentcloud_instance.web)
    load_balancer   = "未設定 - 必要に応じてCLB追加検討"
  }
}

# =============================================================================
# ネットワークゲートウェイ情報出力
# 外部接続とルーティング情報
# =============================================================================

# NATゲートウェイ情報：プライベートサブネット外部接続
output "nat_gateway" {
  description = "NATゲートウェイ情報 - プライベートサブネット外部接続制御"
  value = {
    nat_id         = tencentcloud_nat_gateway.main.id
    nat_name       = tencentcloud_nat_gateway.main.name
    public_ip      = tencentcloud_eip.nat.public_ip
    bandwidth      = tencentcloud_nat_gateway.main.bandwidth
    max_concurrent = tencentcloud_nat_gateway.main.max_concurrent
    vpc_id         = tencentcloud_nat_gateway.main.vpc_id
  }
}

# ルーティング情報：ネットワーク経路設定
output "routing_info" {
  description = "ルーティング情報 - ネットワーク経路とアクセス制御"
  value = {
    public_route_table   = tencentcloud_route_table.public.id
    private_route_tables = [for rt in tencentcloud_route_table.private : rt.id]
    internet_access = {
      bastion_hosts = "直接インターネットアクセス（双方向）"
      web_servers   = "NATゲートウェイ経由（アウトバウンドのみ）"
    }
  }
}

# =============================================================================
# セキュリティ情報出力
# ファイアウォールとアクセス制御設定
# =============================================================================

# セキュリティグループ情報：ファイアウォールルール
output "security_groups" {
  description = "セキュリティグループ情報 - ファイアウォールとアクセス制御"
  value = {
    bastion_sg = {
      id          = tencentcloud_security_group.bastion.id
      name        = tencentcloud_security_group.bastion.name
      description = "踏み台サーバー用 - SSH管理アクセス制御"
    }
    web_sg = {
      id          = tencentcloud_security_group.web.id
      name        = tencentcloud_security_group.web.name
      description = "Webサーバー用 - HTTP/HTTPS + 内部SSH制御"
    }
  }
}

# SSHキー情報：認証管理
output "ssh_key_info" {
  description = "SSHキー情報 - セキュアアクセス認証"
  value = {
    key_pair_id   = tencentcloud_key_pair.main.id
    key_pair_name = tencentcloud_key_pair.main.key_name
    public_key    = tencentcloud_key_pair.main.public_key
    usage_note    = "全インスタンスで共通使用 - 秘密鍵の安全な管理が必要"
  }
}

# =============================================================================
# 運用管理情報出力
# 監視、メンテナンス、トラブルシューティング用
# =============================================================================

# アクセス手順：運用ガイド
output "access_instructions" {
  description = "アクセス手順 - 運用とトラブルシューティングガイド"
  value = {
    bastion_access = {
      step1 = "SSH秘密鍵の準備: ~/.ssh/${var.key_pair_name}.pem"
      step2 = "権限設定: chmod 600 ~/.ssh/${var.key_pair_name}.pem"
      step3 = "踏み台サーバー接続: ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${length(tencentcloud_instance.bastion) > 0 ? tencentcloud_instance.bastion[0].public_ip : "PENDING"}"
    }
    web_access = {
      step1 = "SSH Agent転送有効化: ssh-add ~/.ssh/${var.key_pair_name}.pem"
      step2 = "踏み台サーバー経由接続: ssh -A ubuntu@${length(tencentcloud_instance.bastion) > 0 ? tencentcloud_instance.bastion[0].public_ip : "PENDING"}"
      step3 = "Webサーバー接続: ssh ubuntu@<web_server_private_ip>"
      step4 = "HTTP確認: curl http://<web_server_private_ip>"
    }
  }
}

# コスト情報：料金管理
output "cost_estimation" {
  description = "コスト概算 - 月額料金の目安（実際の料金は使用量により変動）"
  value = {
    compute_instances = {
      bastion_hosts = "${length(tencentcloud_instance.bastion)} x ${var.bastion_instance_type}"
      web_servers   = "${length(tencentcloud_instance.web)} x ${var.web_instance_type}"
    }
    network_resources = {
      nat_gateway = "1 x ${var.nat_bandwidth}Mbps"
      eip_count   = "3個（踏み台サーバー2 + NAT 1）"
    }
    optimization_tips = [
      "予約インスタンス利用でコスト削減可能",
      "不要時のインスタンス停止でコスト節約",
      "CloudWatch監視で使用量最適化"
    ]
  }
}

# =============================================================================
# 出力値設計の考慮事項:
# 
# 情報の分類と整理:
# 1. 接続情報：日常運用で頻繁に参照される情報
# 2. 管理情報：監視、メンテナンス用の技術詳細
# 3. セキュリティ情報：アクセス制御とコンプライアンス用
# 4. 運用ガイド：手順書として活用可能な実用情報
# 
# セキュリティ考慮事項:
# 1. 機密情報の出力回避（秘密鍵、パスワード等）
# 2. 必要最小限の情報公開
# 3. アクセス手順の明確化によるセキュリティ向上
# 
# 運用性向上:
# 1. コピー&ペースト可能なコマンド提供
# 2. トラブルシューティング支援情報
# 3. コスト管理支援情報
# 
# 拡張性確保:
# 1. 動的な情報生成（インスタンス数変動対応）
# 2. 環境間での設定差異対応
# 3. 将来の機能追加に対応可能な構造
# =============================================================================