#!/bin/bash

# 快速开发环境设置脚本
set -e

echo "🚀 腾讯云 Terraform 项目快速设置"
echo "=================================="

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker Desktop"
    echo "   下载地址: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

# 检查 VS Code
if ! command -v code &> /dev/null; then
    echo "❌ VS Code 未安装，请先安装 Visual Studio Code"
    echo "   下载地址: https://code.visualstudio.com/"
    exit 1
fi

echo "✅ Docker 已安装: $(docker --version)"
echo "✅ VS Code 已安装: $(code --version | head -n1)"

# 检查 Dev Containers 扩展
echo ""
echo "🔍 检查 VS Code 扩展..."

# 安装 Dev Containers 扩展
echo "📦 安装 Dev Containers 扩展..."
code --install-extension ms-vscode-remote.remote-containers

# 安装其他有用的扩展
echo "📦 安装推荐扩展..."
code --install-extension hashicorp.terraform
code --install-extension ms-vscode.vscode-json
code --install-extension ms-vscode.vscode-yaml
code --install-extension eamodio.gitlens

echo ""
echo "🎯 设置选项:"
echo "1. 使用 Dev Container (推荐)"
echo "2. 本地环境设置"
echo ""

read -p "请选择 (1/2): " choice

case $choice in
    1)
        echo ""
        echo "🐳 Dev Container 设置"
        echo "===================="
        
        # 检查 SSH 密钥
        if [ ! -f ~/.ssh/id_rsa ]; then
            echo "🔑 生成 SSH 密钥..."
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
            echo "✅ SSH 密钥已生成"
        else
            echo "✅ SSH 密钥已存在"
        fi
        
        # 创建腾讯云配置目录
        mkdir -p ~/.tencentcloud
        
        if [ ! -f ~/.tencentcloud/credentials ]; then
            echo ""
            echo "🔧 配置腾讯云凭证..."
            echo "请输入您的腾讯云 API 凭证:"
            read -p "Secret ID: " secret_id
            read -s -p "Secret Key: " secret_key
            echo ""
            
            cat > ~/.tencentcloud/credentials << EOF
[default]
secret_id = $secret_id
secret_key = $secret_key
region = ap-tokyo
EOF
            echo "✅ 腾讯云凭证已配置"
        else
            echo "✅ 腾讯云凭证已存在"
        fi
        
        echo ""
        echo "🚀 启动 Dev Container..."
        echo "VS Code 将打开项目，请选择 'Reopen in Container'"
        
        # 在 VS Code 中打开项目
        code .
        
        echo ""
        echo "📋 下一步操作:"
        echo "1. 等待 Dev Container 构建完成"
        echo "2. 在容器内运行: make check"
        echo "3. 运行: make quick-deploy"
        ;;
        
    2)
        echo ""
        echo "💻 本地环境设置"
        echo "==============="
        
        # 检测操作系统
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "🍎 检测到 macOS"
            
            # 检查 Homebrew
            if ! command -v brew &> /dev/null; then
                echo "📦 安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            echo "📦 安装工具..."
            brew install terraform jq
            
            # 可选工具
            read -p "是否安装额外工具 (tfsec, terraform-docs)? (y/n): " install_extra
            if [[ $install_extra == "y" ]]; then
                brew install tfsec terraform-docs
            fi
            
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "🐧 检测到 Linux"
            
            # 安装 Terraform
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update
            sudo apt install -y terraform jq
            
        else
            echo "❓ 未识别的操作系统，请手动安装 Terraform"
        fi
        
        # SSH 密钥设置
        if [ ! -f ~/.ssh/id_rsa ]; then
            echo "🔑 生成 SSH 密钥..."
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
        fi
        
        # 腾讯云凭证设置
        echo ""
        echo "🔧 设置腾讯云凭证..."
        echo "请设置环境变量:"
        echo "export TENCENTCLOUD_SECRET_ID=\"your-secret-id\""
        echo "export TENCENTCLOUD_SECRET_KEY=\"your-secret-key\""
        
        echo ""
        echo "📋 下一步操作:"
        echo "1. 设置腾讯云环境变量"
        echo "2. 运行: cp terraform.tfvars.example terraform.tfvars"
        echo "3. 编辑: terraform.tfvars"
        echo "4. 运行: make quick-deploy"
        ;;
        
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "🎉 设置完成！"
echo ""
echo "📚 有用的资源:"
echo "- README.md - 完整文档"
echo "- .devcontainer/README.md - Dev Container 指南"
echo "- DEPLOYMENT_CHECKLIST.md - 部署检查清单"
echo "- make help - 查看所有可用命令"
echo ""
echo "🚀 开始您的腾讯云基础设施之旅！"