# Terraform デプロイ用 Makefile

.PHONY: help init plan apply destroy validate fmt check clean status

# デフォルトターゲット
help: ## ヘルプ情報を表示
	@echo "利用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Terraform を初期化
	@echo "🚀 Terraform を初期化中..."
	terraform init
	@echo "✅ Terraform 初期化完了"

validate: ## Terraform 設定を検証
	@echo "🔍 Terraform 設定を検証中..."
	terraform validate
	terraform fmt -check
	@echo "✅ 設定検証完了"

fmt: ## Terraform コードをフォーマット
	@echo "🎨 Terraform コードをフォーマット中..."
	terraform fmt -recursive
	@echo "✅ コードフォーマット完了"

plan: ## 実行プランを表示
	@echo "📋 実行プランを生成中..."
	terraform plan -out=tfplan
	@echo "✅ 実行プラン生成完了"

apply: ## Terraform 設定を適用
	@echo "🚀 インフラストラクチャをデプロイ中..."
	@echo "⚠️  これによりクラウドリソースが作成され、料金が発生します。続行しますか？"
	@read -p "'yes' を入力して続行: " confirm && [ "$$confirm" = "yes" ]
	terraform apply tfplan
	@echo "✅ インフラストラクチャデプロイ完了"

apply-auto: ## 設定を自動適用（確認をスキップ）
	@echo "🚀 インフラストラクチャを自動デプロイ中..."
	terraform apply -auto-approve
	@echo "✅ インフラストラクチャデプロイ完了"

destroy: ## 全リソースを削除
	@echo "💥 インフラストラクチャを削除中..."
	@echo "⚠️  これにより全てのリソースが削除されます。続行しますか？"
	@read -p "'destroy' を入力して確認: " confirm && [ "$$confirm" = "destroy" ]
	terraform destroy
	@echo "✅ インフラストラクチャ削除完了"

status: ## リソース状態を表示
	@echo "📊 リソース状態を確認中..."
	terraform show
	@echo ""
	@echo "📋 出力情報:"
	terraform output

output: ## 出力情報を表示
	@echo "📋 Terraform 出力:"
	terraform output

ssh-bastion: ## 最初の踏み台サーバーに接続
	@echo "🔐 踏み台サーバーに接続中..."
	@BASTION_IP=$$(terraform output -raw bastion_public_ips | jq -r '.[0]'); \
	echo "踏み台サーバーに接続: $$BASTION_IP"; \
	ssh -i ~/.ssh/id_rsa ubuntu@$$BASTION_IP

ssh-web: ## 踏み台サーバー経由で最初の Web サーバーに接続
	@echo "🔐 踏み台サーバー経由で Web サーバーに接続中..."
	@BASTION_IP=$$(terraform output -raw bastion_public_ips | jq -r '.[0]'); \
	WEB_IP=$$(terraform output -raw web_private_ips | jq -r '.[0]'); \
	echo "踏み台サーバー: $$BASTION_IP"; \
	echo "Web サーバー: $$WEB_IP"; \
	ssh -i ~/.ssh/id_rsa -J ubuntu@$$BASTION_IP ubuntu@$$WEB_IP

tunnel-web: ## Web サーバーへの SSH トンネルを作成
	@echo "🌐 Web サーバーへの SSH トンネルを作成中..."
	@BASTION_IP=$$(terraform output -raw bastion_public_ips | jq -r '.[0]'); \
	WEB_IP=$$(terraform output -raw web_private_ips | jq -r '.[0]'); \
	echo "トンネル作成: localhost:8080 -> $$WEB_IP:80"; \
	echo "http://localhost:8080 にアクセスして Web サービスを確認"; \
	ssh -i ~/.ssh/id_rsa -L 8080:$$WEB_IP:80 -N ubuntu@$$BASTION_IP

check: ## 設定と依存関係をチェック
	@echo "🔍 環境をチェック中..."
	@command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform がインストールされていません"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "❌ jq がインストールされていません"; exit 1; }
	@[ -f ~/.ssh/id_rsa.pub ] || { echo "❌ SSH 公開鍵が存在しません: ~/.ssh/id_rsa.pub"; exit 1; }
	@[ -n "$$TENCENTCLOUD_SECRET_ID" ] || { echo "❌ TENCENTCLOUD_SECRET_ID が設定されていません"; exit 1; }
	@[ -n "$$TENCENTCLOUD_SECRET_KEY" ] || { echo "❌ TENCENTCLOUD_SECRET_KEY が設定されていません"; exit 1; }
	@echo "✅ 環境チェック完了"

clean: ## 一時ファイルをクリーンアップ
	@echo "🧹 一時ファイルをクリーンアップ中..."
	rm -f tfplan
	rm -f terraform.tfstate.backup
	rm -rf .terraform/
	@echo "✅ クリーンアップ完了"

cost: ## コストを見積もり（infracost が必要）
	@echo "💰 インフラストラクチャコストを見積もり中..."
	@command -v infracost >/dev/null 2>&1 || { echo "❌ infracost がインストールされていません。https://www.infracost.io/docs/ を参照"; exit 1; }
	infracost breakdown --path .
	@echo "✅ コスト見積もり完了"

security: ## セキュリティチェック（tfsec が必要）
	@echo "🔒 セキュリティチェックを実行中..."
	@command -v tfsec >/dev/null 2>&1 || { echo "❌ tfsec がインストールされていません。https://github.com/aquasecurity/tfsec を参照"; exit 1; }
	tfsec .
	@echo "✅ セキュリティチェック完了"

docs: ## ドキュメントを生成（terraform-docs が必要）
	@echo "📚 ドキュメントを生成中..."
	@command -v terraform-docs >/dev/null 2>&1 || { echo "❌ terraform-docs がインストールされていません"; exit 1; }
	terraform-docs markdown table --output-file TERRAFORM.md .
	@echo "✅ ドキュメント生成完了: TERRAFORM.md"

# クイックデプロイフロー
quick-deploy: check init validate plan apply output ## クイックデプロイ（完全フロー）
	@echo "🎉 クイックデプロイ完了！"

# 完全チェックフロー
full-check: check validate fmt security ## 完全チェック（フォーマット、検証、セキュリティ）
	@echo "🎉 完全チェック完了！"

# 開発環境セットアップ
dev-setup: ## 開発環境をセットアップ
	@echo "🛠️  開発環境をセットアップ中..."
	@echo "必要なツールをインストール中..."
	@command -v brew >/dev/null 2>&1 && { \
		brew install terraform jq; \
		brew install tfsec terraform-docs infracost; \
	} || echo "terraform, jq, tfsec, terraform-docs, infracost を手動でインストールしてください"
	@echo "✅ 開発環境セットアップ完了"

# 監視と状態チェック
monitor: ## リソース状態を監視
	@echo "📊 リソース状態を監視中..."
	@echo "=== VPC 情報 ==="
	@terraform output network_summary | jq .
	@echo ""
	@echo "=== インスタンス状態 ==="
	@echo "踏み台サーバーパブリック IP:"
	@terraform output bastion_public_ips | jq -r '.[]'
	@echo ""
	@echo "Web サーバープライベート IP:"
	@terraform output web_private_ips | jq -r '.[]'
	@echo ""
	@echo "=== SSH 接続コマンド ==="
	@terraform output bastion_ssh_commands | jq -r '.[]'

# 状態ファイルのバックアップ
backup: ## Terraform 状態ファイルをバックアップ
	@echo "💾 状態ファイルをバックアップ中..."
	@mkdir -p backups
	@cp terraform.tfstate backups/terraform.tfstate.$$(date +%Y%m%d_%H%M%S)
	@echo "✅ 状態ファイルを backups/ ディレクトリにバックアップしました"