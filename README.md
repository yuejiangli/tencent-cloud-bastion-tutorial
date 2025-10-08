# 🏗️ TencentCloud Bastion Host Architecture

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?style=flat&logo=terraform)](https://www.terraform.io/)
[![TencentCloud](https://img.shields.io/badge/TencentCloud-Tokyo-00A1EA?style=flat&logo=tencentqq)](https://cloud.tencent.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Enterprise-grade secure network architecture with bastion hosts for TencentCloud**

## 🌍 Language / 语言 / 言語

- **🇺🇸 [English](README.md)** (Current)
- **🇨🇳 [中文文档](docs/README-zh.md)**
- **🇯🇵 [日本語ドキュメント](docs/README-ja.md)**

---

## 🎯 Project Highlights

- 🔒 **Production-Ready Security**: Multi-layered security with bastion hosts, security groups, and network isolation
- 🌐 **Multi-AZ High Availability**: Resources distributed across multiple availability zones
- 🚀 **One-Click Deployment**: Automated infrastructure provisioning with Terraform
- 📊 **Cost Optimized**: Right-sized instances with detailed cost estimation
- 🛠️ **DevOps Ready**: Includes monitoring and maintenance tools
- 📚 **Comprehensive Documentation**: Multi-language support with detailed guides

---

## 🏛️ Architecture Overview

```
Internet Gateway
       |
   Public Subnets (Multi-AZ)
   /              \
Bastion Hosts    NAT Gateway
   |                 |
   |            Private Subnets (Multi-AZ)
   |                 |
   └─────────► Web Servers
```

### 🔐 Security Layers

| Layer | Component | Protection |
|-------|-----------|------------|
| **Network** | VPC Isolation | Private subnets with no direct internet access |
| **Access** | Bastion Hosts | Centralized SSH access control and logging |
| **Firewall** | Security Groups | Granular port and protocol restrictions |
| **Authentication** | SSH Keys | Public key authentication, password disabled |

---

## 🚀 Quick Start

### Prerequisites

- **Terraform** >= 1.0 ([Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- **TencentCloud Account** with API access
- **SSH Client** (OpenSSH recommended)

### Deployment Steps

```bash
# 1. Clone repository
git clone https://github.com/yuejiangli/tencent-cloud-bastion-tutorial.git
cd tencent-cloud-bastion-tutorial

# 2. Configure credentials (choose one method)
# Method A: Environment variables (recommended)
export TENCENTCLOUD_SECRET_ID="your-secret-id"
export TENCENTCLOUD_SECRET_KEY="your-secret-key"

# Method B: Credentials file
mkdir -p ~/.tencentcloud
echo 'secret_id = "your-secret-id"' > ~/.tencentcloud/credentials
echo 'secret_key = "your-secret-key"' >> ~/.tencentcloud/credentials

# 3. Deploy infrastructure
make init      # Initialize Terraform
make plan      # Review deployment plan
make apply     # Deploy infrastructure (takes ~10 minutes)
```

---

## 📦 Infrastructure Components

### 🌐 Network Resources

| Resource | Quantity | Specification | Purpose |
|----------|----------|---------------|---------|
| **VPC** | 1 | 10.0.0.0/16 | Main network container |
| **Public Subnets** | 2 | 10.0.1.0/24, 10.0.2.0/24 | Bastion hosts, NAT gateway |
| **Private Subnets** | 2 | 10.0.10.0/24, 10.0.20.0/24 | Web servers |
| **Internet Gateway** | 1 | Auto-managed | Public internet access |
| **NAT Gateway** | 1 | 100Mbps bandwidth | Private subnet outbound |

### 💻 Compute Resources

| Resource | Quantity | Instance Type | vCPU | Memory | Monthly Cost* |
|----------|----------|---------------|------|--------|---------------|
| **Bastion Hosts** | 2 | S5.MEDIUM4 | 2 | 4GB | ~$60 |
| **Web Servers** | 2 | S5.MEDIUM4 | 2 | 4GB | ~$60 |
| **NAT Gateway** | 1 | Standard | - | - | ~$45 |
| **EIPs** | 3 | Standard | - | - | ~$15 |
| | | | | **Total** | **~$180** |

*Estimated costs for Tokyo region

---

## 🎮 Usage Guide

### 🔑 SSH Access

```bash
# 1. Connect to Bastion Host
ssh -i ~/.ssh/bastion_keypair.pem ubuntu@<bastion-public-ip>

# 2. Connect to Web Server via Bastion (Jump Host)
ssh -i ~/.ssh/bastion_keypair.pem -J ubuntu@<bastion-ip> ubuntu@<web-private-ip>

# 3. SSH Agent Forwarding (Recommended)
ssh-add ~/.ssh/bastion_keypair.pem
ssh -A ubuntu@<bastion-ip>
# Then from bastion:
ssh ubuntu@<web-private-ip>

# 4. Port Forwarding for Web Access
ssh -i ~/.ssh/bastion_keypair.pem -L 8080:<web-private-ip>:80 ubuntu@<bastion-ip>
# Access via: http://localhost:8080
```

### 🛠️ Management Commands

```bash
# Infrastructure Management
make plan              # Preview changes
make apply             # Apply changes
make destroy           # Destroy infrastructure
make refresh           # Refresh state

# Monitoring & Maintenance
make status            # Check resource status
make logs              # View deployment logs
make validate          # Validate configuration
make format            # Format Terraform files

# Get deployment information
terraform output       # Show all outputs
terraform output bastion_public_ips    # Show bastion IPs
terraform output web_private_ips       # Show web server IPs
```

---

## 🔧 Customization

### Configuration Options

Copy and modify `terraform.tfvars.example`:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferences
```

Key configuration options:

```hcl
# Basic Configuration
project_name = "my-bastion-project"
environment  = "production"

# Instance Configuration
bastion_instance_type = "S5.LARGE8"    # Upgrade for higher performance
web_instance_type     = "S5.LARGE8"    # Upgrade for higher performance
instance_count        = 3              # Scale up web servers

# Network Configuration
vpc_cidr = "10.0.0.0/16"
allowed_ssh_cidrs = ["203.0.113.0/24"] # Restrict SSH access
```

---

## 🛡️ Security Best Practices

### ✅ Implemented Security Measures

- [x] **Network Segmentation**: Private subnets isolated from internet
- [x] **Bastion Host Access**: Centralized SSH access control
- [x] **Security Groups**: Least privilege firewall rules
- [x] **SSH Key Authentication**: Password authentication disabled
- [x] **Encrypted Storage**: EBS volumes encrypted at rest

### 🔍 Security Checklist

Before production deployment:

- [ ] Review and customize security group rules
- [ ] Implement SSH key rotation policy
- [ ] Configure monitoring and alerting
- [ ] Set up backup procedures
- [ ] Conduct security testing

---

## 🐛 Troubleshooting

### Common Issues

**SSH Connection Failed**
```bash
# Check security group rules
terraform state show tencentcloud_security_group.bastion

# Verify SSH key permissions
chmod 600 ~/.ssh/bastion_keypair.pem

# Test connectivity
telnet <bastion-ip> 22
```

**Web Servers Cannot Access Internet**
```bash
# Check NAT Gateway status
terraform state show tencentcloud_nat_gateway.main

# Verify route table configuration
terraform state show tencentcloud_route_table.private
```

**Authentication Errors**
```bash
# Verify credentials are set
echo $TENCENTCLOUD_SECRET_ID
echo $TENCENTCLOUD_SECRET_KEY

# Or check credentials file
cat ~/.tencentcloud/credentials
```

---

## 💰 Cost Optimization

### Cost Reduction Strategies

```bash
# Use smaller instances for development
terraform apply -var="bastion_instance_type=S5.SMALL2"
terraform apply -var="web_instance_type=S5.SMALL2"

# Enable spot instances (70% cost reduction)
terraform apply -var="enable_spot_instances=true"

# Scale down for testing
terraform apply -var="instance_count=1"
```

### Monthly Cost Breakdown

- **Development Environment**: ~$80/month (smaller instances)
- **Production Environment**: ~$180/month (current configuration)
- **High Performance**: ~$300/month (larger instances)

---

## 📚 Documentation

### File Structure

```
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── versions.tf                # Provider versions
├── compute.tf                 # EC2 instances and key pairs
├── network.tf                 # VPC, subnets, gateways
├── security.tf                # Security groups and rules
├── scripts/
│   ├── bastion_userdata.sh    # Bastion host initialization
│   └── web_userdata.sh        # Web server initialization
├── terraform.tfvars.example   # Example configuration
├── Makefile                   # Automation commands
├── DEPLOYMENT_CHECKLIST.md    # Deployment checklist
└── docs/
    ├── README-zh.md           # Chinese documentation
    └── README-ja.md           # Japanese documentation
```

### Additional Resources

- [Terraform TencentCloud Provider](https://registry.terraform.io/providers/tencentcloudstack/tencentcloud/latest/docs)
- [TencentCloud VPC Documentation](https://cloud.tencent.com/document/product/215)
- [Network Security Best Practices](https://cloud.tencent.com/document/product/215/20046)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yuejiangli/tencent-cloud-bastion-tutorial.git

# Install pre-commit hooks
pre-commit install

# Run tests
make test
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [HashiCorp Terraform](https://www.terraform.io/) for infrastructure as code
- [TencentCloud](https://cloud.tencent.com/) for reliable cloud infrastructure
- Community contributors for improvements and feedback

---

<div align="center">

**⭐ If this project helped you, please give it a star! ⭐**

[![GitHub stars](https://img.shields.io/github/stars/yuejiangli/tencent-cloud-bastion-tutorial?style=social)](https://github.com/yuejiangli/tencent-cloud-bastion-tutorial/stargazers)

**Made with ❤️ for the DevOps community**

</div>