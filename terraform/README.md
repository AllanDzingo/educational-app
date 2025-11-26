# Terraform Infrastructure for Educational App

This directory contains Terraform configurations for deploying the Educational App to Google Cloud Platform.

## Deployment Options

### Option 1: GKE (Google Kubernetes Engine)
- **Directory**: `gke/`
- **Best for**: Full Kubernetes control, complex orchestration
- **Uses**: Your existing Kubernetes manifests
- **Cost**: Cluster runs 24/7 (higher cost)

### Option 2: Cloud Run
- **Directory**: `cloud-run/`
- **Best for**: Simpler deployment, automatic scaling
- **Uses**: Docker containers with automatic builds from GitHub
- **Cost**: Pay only for requests (lower cost)

## Prerequisites

1. **Google Cloud Account** with billing enabled
2. **gcloud CLI** installed: https://cloud.google.com/sdk/docs/install
3. **Terraform** installed: https://www.terraform.io/downloads
4. **GitHub repository** pushed to: https://github.com/AllanDzingo/educational-app

## Quick Start

### 1. Authenticate with Google Cloud
```bash
gcloud auth login
gcloud auth application-default login
```

### 2. Set your project ID
```bash
export TF_VAR_project_id="your-gcp-project-id"
```

### 3. Choose your deployment option

#### For GKE:
```bash
cd terraform/gke
terraform init
terraform plan
terraform apply
```

#### For Cloud Run:
```bash
cd terraform/cloud-run
terraform init
terraform plan
terraform apply
```

## Configuration

Each deployment option has a `terraform.tfvars.example` file. Copy it to `terraform.tfvars` and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

## Cost Estimates

### GKE (24/7 running)
- Small cluster: ~$70-100/month
- Includes: 1 node, load balancer, persistent storage

### Cloud Run (pay-per-use)
- Light traffic: ~$5-20/month
- Includes: Automatic scaling, HTTPS, load balancing

## Recommendation

**Start with Cloud Run** for:
- Lower costs
- Simpler management
- Automatic scaling
- Built-in HTTPS

**Use GKE** if you need:
- Advanced Kubernetes features
- Custom networking
- Persistent connections
- More control over infrastructure
