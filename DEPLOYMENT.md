# Deployment Guide - Educational App

This application can be deployed to Google Cloud Platform using **Cloud Run** (recommended) or **GKE**.

## Quick Start - Cloud Run (Recommended)

Cloud Run is the simplest and most cost-effective way to deploy this application.

### Prerequisites
- Google Cloud account with billing enabled
- gcloud CLI installed
- Terraform installed
- MongoDB Atlas account (free tier available)

### Deploy in 5 Steps

1. **Set up Google Cloud**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Set up MongoDB Atlas**
   - Create free cluster at https://www.mongodb.com/cloud/atlas
   - Get connection string
   - Whitelist all IPs (0.0.0.0/0)

3. **Configure Terraform**
   ```bash
   cd terraform/cloud-run
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project ID and MongoDB URI
   ```

4. **Build and Push Images**
   ```bash
   # See terraform/cloud-run/README.md for detailed commands
   ```

5. **Deploy**
   ```bash
   terraform init
   terraform apply
   ```

### Full Documentation
See [terraform/cloud-run/README.md](terraform/cloud-run/README.md) for complete step-by-step instructions.

## Alternative - GKE Deployment

For more control and Kubernetes features, use GKE:

See [terraform/gke/README.md](terraform/gke/README.md) for instructions.

## CI/CD - Automatic Deployment

The `cloudbuild.yaml` file enables automatic deployment from GitHub:

1. Push code to GitHub
2. Cloud Build automatically builds Docker images
3. Deploys to Cloud Run

Set up with:
```bash
gcloud builds triggers create github \
  --repo-name=educational-app \
  --repo-owner=AllanDzingo \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

## Architecture

```
┌─────────────┐
│   Frontend  │ (Cloud Run)
│  (React)    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ API Gateway │ (Cloud Run)
│  (Node.js)  │
└──────┬──────┘
       │
       ├──────────┬──────────┬──────────┐
       ▼          ▼          ▼          ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│   Auth   │ │ Learning │ │ Payment  │ (Cloud Run)
│ Service  │ │ Service  │ │ Service  │
└────┬─────┘ └──────────┘ └──────────┘
     │
     ▼
┌──────────┐
│ MongoDB  │ (Atlas)
│ Database │
└──────────┘
```

## Cost Estimates

### Cloud Run (Recommended)
- **Light traffic**: $5-20/month
- **Medium traffic**: $20-50/month
- Includes: Auto-scaling, HTTPS, Load balancing

### GKE
- **Small cluster**: $70-100/month
- **Medium cluster**: $150-300/month
- More control but higher base cost

## Monitoring

- **Cloud Console**: https://console.cloud.google.com/run
- **Logs**: `gcloud run services logs read SERVICE_NAME`
- **Metrics**: Available in Cloud Console

## Support

For deployment issues, see:
- [Cloud Run README](terraform/cloud-run/README.md)
- [GKE README](terraform/gke/README.md)
- [Main README](README.md)
