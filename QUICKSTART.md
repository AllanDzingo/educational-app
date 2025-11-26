# Quick Start - Deploy to Cloud Run

This script automates the entire deployment process.

## Prerequisites

1. **Google Cloud account** with billing enabled
2. **gcloud CLI** installed and authenticated
3. **Docker** installed and running
4. **Terraform** installed
5. **MongoDB Atlas** connection string

## Usage

```powershell
.\deploy-cloud-run.ps1 -ProjectId "your-gcp-project-id" -MongoDbUri "mongodb+srv://user:pass@cluster.mongodb.net/db"
```

### Optional Parameters

```powershell
.\deploy-cloud-run.ps1 `
    -ProjectId "your-project-id" `
    -MongoDbUri "mongodb+srv://..." `
    -Region "us-central1"
```

## What This Script Does

1. ✅ Sets your GCP project
2. ✅ Enables required APIs (Cloud Run, Cloud Build, Artifact Registry)
3. ✅ Creates Artifact Registry repository
4. ✅ Builds all Docker images
5. ✅ Pushes images to Artifact Registry
6. ✅ Creates Terraform configuration
7. ✅ Deploys all services to Cloud Run
8. ✅ Outputs your application URLs

## Example

```powershell
.\deploy-cloud-run.ps1 `
    -ProjectId "educational-app-123456" `
    -MongoDbUri "mongodb+srv://admin:password@cluster0.mongodb.net/educational-app"
```

## After Deployment

The script will output your service URLs:

```
frontend_url = "https://frontend-xxxxx-uc.a.run.app"
api_gateway_url = "https://api-gateway-xxxxx-uc.a.run.app"
```

Visit the frontend URL in your browser to access your application!

## Updating Your App

Simply run the script again after making changes:

```powershell
.\deploy-cloud-run.ps1 -ProjectId "your-project-id" -MongoDbUri "mongodb+srv://..."
```

## Troubleshooting

### "gcloud: command not found"
Install gcloud CLI: https://cloud.google.com/sdk/docs/install

### "docker: command not found"
Make sure Docker Desktop is running

### "terraform: command not found"
Install Terraform: https://www.terraform.io/downloads

### MongoDB connection errors
- Verify your connection string
- Whitelist all IPs (0.0.0.0/0) in MongoDB Atlas
- Check database user permissions

## Manual Deployment

If you prefer manual deployment, see:
- [terraform/cloud-run/README.md](terraform/cloud-run/README.md)
- [DEPLOYMENT.md](DEPLOYMENT.md)
