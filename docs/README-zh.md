# 🏗️ 腾讯云堡垒机架构

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?style=flat&logo=terraform)](https://www.terraform.io/)
[![TencentCloud](https://img.shields.io/badge/TencentCloud-Tokyo-00A1EA?style=flat&logo=tencentqq)](https://cloud.tencent.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

> **腾讯云企业级安全网络架构 - 包含堡垒机的完整解决方案**

## 🌍 语言选择

- **🇺🇸 [English](../README.md)**
- **🇨🇳 [中文文档](README-zh.md)** (当前)
- **🇯🇵 [日本語ドキュメント](README-ja.md)**

---

## 🎯 项目亮点

- 🔒 **生产级安全**: 多层安全防护，包含堡垒机、安全组和网络隔离
- 🌐 **多可用区高可用**: 资源分布在多个可用区，确保高可用性
- 🚀 **一键部署**: 使用 Terraform 自动化基础设施供应
- 📊 **成本优化**: 合理配置实例规格，提供详细成本估算
- 🛠️ **DevOps 就绪**: 包含监控和维护工具
- 📚 **完整文档**: 多语言支持，详细使用指南

---

## 🏛️ 架构概述

```
互联网网关
    |
公有子网 (多可用区)
  /        \
堡垒机    NAT网关
  |         |
  |    私有子网 (多可用区)
  |         |
  └─────► Web服务器
```

### 🔐 安全层级

| 层级 | 组件 | 防护措施 |
|------|------|----------|
| **网络** | VPC隔离 | 私有子网无直接互联网访问 |
| **访问** | 堡垒机 | 集中化SSH访问控制和日志记录 |
| **防火墙** | 安全组 | 精细化端口和协议限制 |
| **认证** | SSH密钥 | 公钥认证，禁用密码登录 |

---

## 🚀 快速开始

### 前置要求

- **Terraform** >= 1.0 ([安装指南](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- **腾讯云账号** 并开通API访问
- **SSH客户端** (推荐OpenSSH)

### 部署步骤

```bash
# 1. 克隆仓库
git clone https://github.com/yuejiangli/tencent-cloud-bastion-tutorial.git
cd tencent-cloud-bastion-tutorial

# 2. 配置凭证 (选择一种方式)
# 方式A: 环境变量 (推荐)
export TENCENTCLOUD_SECRET_ID="your-secret-id"
export TENCENTCLOUD_SECRET_KEY="your-secret-key"

# 方式B: 凭证文件
mkdir -p ~/.tencentcloud
echo 'secret_id = "your-secret-id"' > ~/.tencentcloud/credentials
echo 'secret_key = "your-secret-key"' >> ~/.tencentcloud/credentials

# 3. 部署基础设施
make init      # 初始化Terraform
make plan      # 查看部署计划
make apply     # 部署基础设施 (大约需要10分钟)
```

---

## 📦 基础设施组件

### 🌐 网络资源

| 资源 | 数量 | 规格 | 用途 |
|------|------|------|------|
| **VPC** | 1 | 10.0.0.0/16 | 主网络容器 |
| **公有子网** | 2 | 10.0.1.0/24, 10.0.2.0/24 | 堡垒机、NAT网关 |
| **私有子网** | 2 | 10.0.10.0/24, 10.0.20.0/24 | Web服务器 |
| **互联网网关** | 1 | 自动管理 | 公网访问 |
| **NAT网关** | 1 | 100Mbps带宽 | 私有子网出站 |

### 💻 计算资源

| 资源 | 数量 | 实例类型 | vCPU | 内存 | 月费用* |
|------|------|----------|------|------|---------|
| **堡垒机** | 2 | S5.MEDIUM4 | 2 | 4GB | ~$60 |
| **Web服务器** | 2 | S5.MEDIUM4 | 2 | 4GB | ~$60 |
| **NAT网关** | 1 | 标准 | - | - | ~$45 |
| **弹性IP** | 3 | 标准 | - | - | ~$15 |
| | | | | **总计** | **~$180** |

*东京地域预估费用

---

## 🎮 使用指南

### 🔑 SSH访问

```bash
# 1. 连接堡垒机
ssh -i ~/.ssh/bastion_keypair.pem ubuntu@<堡垒机公网IP>

# 2. 通过堡垒机连接Web服务器 (跳板机)
ssh -i ~/.ssh/bastion_keypair.pem -J ubuntu@<堡垒机IP> ubuntu@<Web服务器私网IP>

# 3. SSH代理转发 (推荐)
ssh-add ~/.ssh/bastion_keypair.pem
ssh -A ubuntu@<堡垒机IP>
# 然后在堡垒机上:
ssh ubuntu@<Web服务器私网IP>

# 4. 端口转发访问Web服务
ssh -i ~/.ssh/bastion_keypair.pem -L 8080:<Web服务器私网IP>:80 ubuntu@<堡垒机IP>
# 通过浏览器访问: http://localhost:8080
```

### 🛠️ 管理命令

```bash
# 基础设施管理
make plan              # 预览变更
make apply             # 应用变更
make destroy           # 销毁基础设施
make refresh           # 刷新状态

# 监控维护
make status            # 检查资源状态
make logs              # 查看部署日志
make validate          # 验证配置
make format            # 格式化Terraform文件

# 获取部署信息
terraform output       # 显示所有输出
terraform output bastion_public_ips    # 显示堡垒机IP
terraform output web_private_ips       # 显示Web服务器IP
```

---

## 🔧 自定义配置

### 配置选项

复制并修改 `terraform.tfvars.example`:

```bash
cp terraform.tfvars.example terraform.tfvars
# 编辑 terraform.tfvars 文件设置你的偏好
```

主要配置选项:

```hcl
# 基础配置
project_name = "my-bastion-project"
environment  = "production"

# 实例配置
bastion_instance_type = "S5.LARGE8"    # 升级以获得更高性能
web_instance_type     = "S5.LARGE8"    # 升级以获得更高性能
instance_count        = 3              # 扩展Web服务器数量

# 网络配置
vpc_cidr = "10.0.0.0/16"
allowed_ssh_cidrs = ["203.0.113.0/24"] # 限制SSH访问
```

---

## 🛡️ 安全最佳实践

### ✅ 已实施的安全措施

- [x] **网络分段**: 私有子网与互联网隔离
- [x] **堡垒机访问**: 集中化SSH访问控制
- [x] **安全组**: 最小权限防火墙规则
- [x] **SSH密钥认证**: 禁用密码认证
- [x] **加密存储**: EBS卷静态加密

### 🔍 安全检查清单

生产部署前:

- [ ] 审查并自定义安全组规则
- [ ] 实施SSH密钥轮换策略
- [ ] 配置监控和告警
- [ ] 设置备份程序
- [ ] 进行安全测试

---

## 🐛 故障排除

### 常见问题

**SSH连接失败**
```bash
# 检查安全组规则
terraform state show tencentcloud_security_group.bastion

# 验证SSH密钥权限
chmod 600 ~/.ssh/bastion_keypair.pem

# 测试连通性
telnet <堡垒机IP> 22
```

**Web服务器无法访问互联网**
```bash
# 检查NAT网关状态
terraform state show tencentcloud_nat_gateway.main

# 验证路由表配置
terraform state show tencentcloud_route_table.private
```

**认证错误**
```bash
# 验证凭证是否设置
echo $TENCENTCLOUD_SECRET_ID
echo $TENCENTCLOUD_SECRET_KEY

# 或检查凭证文件
cat ~/.tencentcloud/credentials
```

---

## 💰 成本优化

### 成本降低策略

```bash
# 开发环境使用更小的实例
terraform apply -var="bastion_instance_type=S5.SMALL2"
terraform apply -var="web_instance_type=S5.SMALL2"

# 启用竞价实例 (70%成本降低)
terraform apply -var="enable_spot_instances=true"

# 测试时缩减规模
terraform apply -var="instance_count=1"
```

### 月度成本分解

- **开发环境**: ~$80/月 (较小实例)
- **生产环境**: ~$180/月 (当前配置)
- **高性能环境**: ~$300/月 (更大实例)

---

## 📚 文档

### 文件结构

```
├── main.tf                    # 主Terraform配置
├── variables.tf               # 变量定义
├── outputs.tf                 # 输出定义
├── versions.tf                # 提供商版本
├── compute.tf                 # EC2实例和密钥对
├── network.tf                 # VPC、子网、网关
├── security.tf                # 安全组和规则
├── scripts/
│   ├── bastion_userdata.sh    # 堡垒机初始化脚本
│   └── web_userdata.sh        # Web服务器初始化脚本
├── terraform.tfvars.example   # 配置示例
├── Makefile                   # 自动化命令
├── DEPLOYMENT_CHECKLIST.md    # 部署检查清单
└── docs/
    ├── README-zh.md           # 中文文档
    └── README-ja.md           # 日文文档
```

### 额外资源

- [Terraform腾讯云提供商](https://registry.terraform.io/providers/tencentcloudstack/tencentcloud/latest/docs)
- [腾讯云VPC文档](https://cloud.tencent.com/document/product/215)
- [网络安全最佳实践](https://cloud.tencent.com/document/product/215/20046)

---

## 🤝 贡献

欢迎贡献！请随时提交Pull Request。

### 开发设置

```bash
# 克隆仓库
git clone https://github.com/yuejiangli/tencent-cloud-bastion-tutorial.git

# 安装pre-commit钩子
pre-commit install

# 运行测试
make test
```

---

## 📄 许可证

本项目采用MIT许可证 - 详见 [LICENSE](../LICENSE) 文件。

---

## 🙏 致谢

- [HashiCorp Terraform](https://www.terraform.io/) 提供基础设施即代码
- [腾讯云](https://cloud.tencent.com/) 提供可靠的云基础设施
- 社区贡献者的改进和反馈

---

<div align="center">

**⭐ 如果这个项目对您有帮助，请给个星标！ ⭐**

[![GitHub stars](https://img.shields.io/github/stars/yuejiangli/tencent-cloud-bastion-tutorial?style=social)](https://github.com/yuejiangli/tencent-cloud-bastion-tutorial/stargazers)

**用 ❤️ 为DevOps社区制作**

</div>