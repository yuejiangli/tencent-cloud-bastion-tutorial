# =============================================================================
# コンピュートリソース設定
# 踏み台サーバー（Bastion Host）とWebサーバーのインスタンス定義
# =============================================================================

# SSH鍵ペア設定
# 全てのサーバーインスタンスで共通使用する認証鍵
# セキュリティ：パスワード認証を無効化し、公開鍵認証のみを使用
resource "tencentcloud_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = file("~/.ssh/id_rsa.pub") # ローカルのSSH公開鍵を使用

  tags = merge(var.common_tags, {
    ResourceName = var.key_pair_name
  })
}

# =============================================================================
# 踏み台サーバー（Bastion Host）設定
# セキュアな管理アクセスのためのジャンプサーバー
# =============================================================================

# 踏み台サーバー用EIP（Elastic IP）
# 管理者がインターネット経由でアクセスするためのパブリックIP
resource "tencentcloud_eip" "bastion" {
  count = length(tencentcloud_subnet.public) # マルチAZ対応

  name                       = "${var.project_name}-bastion-eip-${count.index + 1}-${var.environment}"
  internet_charge_type       = "TRAFFIC_POSTPAID_BY_HOUR" # トラフィック従量課金
  internet_max_bandwidth_out = 100                        # アウトバウンド帯域幅: 100Mbps

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-bastion-eip-${count.index + 1}-${var.environment}"
    ResourceType = "bastion"
  })
}

# 踏み台サーバーインスタンス
# プライベートネットワークへの安全なアクセスポイント
# 機能：SSH踏み台、アクセス監査、セキュリティ制御
resource "tencentcloud_instance" "bastion" {
  count = length(tencentcloud_subnet.public) # 各パブリックサブネットに1台ずつ配置

  instance_name              = "${var.project_name}-bastion-${count.index + 1}-${var.environment}"
  availability_zone          = var.availability_zones[count.index]      # 高可用性のためのマルチAZ
  image_id                   = var.instance_image_id                    # Ubuntu 20.04 LTS
  instance_type              = var.bastion_instance_type                # S5.MEDIUM4 (2vCPU, 4GB RAM)
  system_disk_type           = "CLOUD_PREMIUM"                          # プレミアムSSD
  system_disk_size           = 50                                       # システムディスク: 50GB
  allocate_public_ip         = false                                    # EIPを使用するため無効
  internet_max_bandwidth_out = 0                                        # EIP経由でアクセス
  key_ids                    = [tencentcloud_key_pair.main.id]          # SSH鍵認証
  orderly_security_groups    = [tencentcloud_security_group.bastion.id] # 踏み台サーバー専用セキュリティグループ
  subnet_id                  = tencentcloud_subnet.public[count.index].id
  vpc_id                     = tencentcloud_vpc.main.id

  # ユーザーデータスクリプト - 踏み台サーバー初期化
  # セキュリティツール、監視ツール、ログ設定などを自動インストール
  user_data = base64encode(templatefile("${path.module}/scripts/bastion_userdata.sh", {
    hostname = "${var.project_name}-bastion-${count.index + 1}"
  }))

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-bastion-${count.index + 1}-${var.environment}"
    ResourceType = "bastion"
  })
}

# 踏み台サーバーEIP関連付け
# インスタンスとElastic IPの紐付け
resource "tencentcloud_eip_association" "bastion" {
  count = length(tencentcloud_instance.bastion)

  eip_id      = tencentcloud_eip.bastion[count.index].id
  instance_id = tencentcloud_instance.bastion[count.index].id
}

# =============================================================================
# Webサーバー設定
# アプリケーション実行環境（プライベートサブネット配置）
# =============================================================================

# Webサーバーインスタンス
# プライベートサブネットに配置されたアプリケーションサーバー
# セキュリティ：インターネットから直接アクセス不可、踏み台サーバー経由のみ
resource "tencentcloud_instance" "web" {
  count = length(tencentcloud_subnet.private) # 各プライベートサブネットに1台ずつ配置

  instance_name              = "${var.project_name}-web-${count.index + 1}-${var.environment}"
  availability_zone          = var.availability_zones[count.index]  # 高可用性のためのマルチAZ
  image_id                   = var.instance_image_id                # Ubuntu 20.04 LTS
  instance_type              = var.web_instance_type                # S5.MEDIUM4 (2vCPU, 4GB RAM)
  system_disk_type           = "CLOUD_PREMIUM"                      # プレミアムSSD
  system_disk_size           = 100                                  # システムディスク: 100GB
  allocate_public_ip         = false                                # プライベートIPのみ
  internet_max_bandwidth_out = 0                                    # 直接インターネットアクセス無し
  key_ids                    = [tencentcloud_key_pair.main.id]      # SSH鍵認証（踏み台サーバーと同じ鍵）
  orderly_security_groups    = [tencentcloud_security_group.web.id] # Web専用セキュリティグループ
  subnet_id                  = tencentcloud_subnet.private[count.index].id
  vpc_id                     = tencentcloud_vpc.main.id

  # ユーザーデータスクリプト - Webサーバー初期化
  # Nginx、Node.js、監視ツールなどを自動インストール・設定
  user_data = base64encode(templatefile("${path.module}/scripts/web_userdata.sh", {
    hostname = "${var.project_name}-web-${count.index + 1}"
  }))

  tags = merge(var.common_tags, {
    ResourceName = "${var.project_name}-web-${count.index + 1}-${var.environment}"
    ResourceType = "web"
  })
}

# =============================================================================
# アクセスフロー:
# 
# 管理者 → 踏み台サーバー（SSH） → Webサーバー（SSH Agent Forwarding）
# Webサーバー → NATゲートウェイ → インターネット（アウトバウンドのみ）
# 
# セキュリティ機能:
# - SSH鍵認証のみ（パスワード認証無効）
# - セキュリティグループによるポート制限
# - プライベートサブネットによるネットワーク隔離
# - 踏み台サーバーによる集中アクセス制御
# =============================================================================