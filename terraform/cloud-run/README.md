# Cloud Run Deployment Guide

This guide will help you deploy the Educational App to Google Cloud Run using Terraform.

## Why Cloud Run?

✅ **Serverless** - No cluster management
✅ **Auto-scaling** - Scales to zero when not in use
✅ **Cost-effective** - Pay only for requests
✅ **Simple** - Easy deployment from GitHub
✅ **HTTPS** - Automatic SSL certificates

## Prerequisites

1. **Google Cloud Account** with billing enabled
2. **gcloud CLI** installed
3. **Terraform** installed
4. **Docker images** built and ready
5. **MongoDB** (use MongoDB Atlas for production)

## Step-by-Step Deployment

### 1. Install Prerequisites

#### Install gcloud CLI (if not installed)
```bash
# Download from: https://cloud.google.com/sdk/docs/install
# Or use installer for Windows
```

#### Install Terraform (if not installed)
```bash
# Download from: https://www.terraform.io/downloads
# Or use Chocolatey on Windows:
choco install terraform
```

### 2. Authenticate with Google Cloud

```bash
# Login to Google Cloud
gcloud auth login

# Set up application default credentials for Terraform
gcloud auth application-default login

# Create a new project (or use existing)
gcloud projects create educational-app-PROJECT_ID --name="Educational App"

# Set the project
gcloud config set project educational-app-PROJECT_ID

# Enable billing (required for Cloud Run)
# Visit: https://console.cloud.google.com/billing
```

### 3. Set Up MongoDB

For production, use **MongoDB Atlas** (free tier available):

1. Go to https://www.mongodb.com/cloud/atlas
2. Create a free cluster
3. Get your connection string
4. Whitelist all IPs (0.0.0.0/0) for Cloud Run access

Your connection string will look like:
```
mongodb+srv://username:password@cluster.mongodb.net/educational-app
```

### 4. Configure Terraform Variables

```bash
cd terraform/cloud-run

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
notepad terraform.tfvars
```

Update `terraform.tfvars`:
```hcl
project_id  = "educational-app-123456"  # Your GCP project ID
region      = "us-central1"
mongodb_uri = "mongodb+srv://user:pass@cluster.mongodb.net/educational-app"
github_repo = "AllanDzingo/educational-app"
```

### 5. Build and Push Docker Images

First, we need to build and push images to Google Artifact Registry:

```bash
# Go to project root
cd ../..

# Set environment variables
$PROJECT_ID = "your-project-id"
$REGION = "us-central1"

# Configure Docker to use gcloud credentials
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Build and push each service
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/auth-service:latest ./auth-service
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/auth-service:latest

docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/learning-service:latest ./learning-service
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/learning-service:latest

docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/payment-service:latest ./payment-service
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/payment-service:latest

docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/api-gateway:latest ./api-gateway
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/api-gateway:latest

docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/frontend:latest ./frontend
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/educational-app/frontend:latest
```

### 6. Deploy with Terraform

```bash
cd terraform/cloud-run

# Initialize Terraform
terraform init

# Preview the changes
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted.

### 7. Get Your URLs

After deployment completes, Terraform will output your service URLs:

```bash
# View outputs
terraform output

# You'll see:
# frontend_url = "https://frontend-xxxxx-uc.a.run.app"
# api_gateway_url = "https://api-gateway-xxxxx-uc.a.run.app"
```

### 8. Set Up CI/CD (Optional)

To automatically deploy when you push to GitHub:

```bash
# Go to project root
cd ../..

# Create Cloud Build trigger
gcloud builds triggers create github \
  --repo-name=educational-app \
  --repo-owner=AllanDzingo \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

Now every push to `main` branch will automatically deploy!

## Testing Your Deployment

```bash
# Get the frontend URL
terraform output frontend_url

# Open in browser or test with curl
curl $(terraform output -raw frontend_url)

# Test API Gateway
curl $(terraform output -raw api_gateway_url)/health
```

## Updating Your Application

### Manual Update
```bash
# Rebuild and push images (see step 5)
# Then apply Terraform again
terraform apply
```

### Automatic Update (with CI/CD)
```bash
# Just push to GitHub
git add .
git commit -m "Update application"
git push origin main
```

## Cost Estimation

Cloud Run pricing (as of 2024):
- **Free tier**: 2 million requests/month
- **After free tier**: ~$0.40 per million requests
- **Memory**: ~$0.0000025 per GB-second
- **CPU**: ~$0.00002400 per vCPU-second

**Estimated monthly cost for light traffic**: $5-20/month

## Monitoring

View logs and metrics:
```bash
# View logs for a service
gcloud run services logs read auth-service --region=us-central1

# Or visit Cloud Console
# https://console.cloud.google.com/run
```

## Troubleshooting

### Images not found
Make sure you've pushed images to Artifact Registry (step 5)

### Permission denied
Run: `gcloud auth application-default login`

### MongoDB connection failed
- Check your MongoDB Atlas IP whitelist (allow 0.0.0.0/0)
- Verify connection string in terraform.tfvars
- Check MongoDB Atlas user permissions

### Service not accessible
Cloud Run services are public by default. Check IAM settings if needed.

## Cleanup

To delete all resources and stop billing:

```bash
cd terraform/cloud-run
terraform destroy
```

Type `yes` when prompted.

## Next Steps

1. **Custom Domain**: Add your own domain in Cloud Run console
2. **Monitoring**: Set up Cloud Monitoring alerts
3. **Secrets**: Move sensitive data to Secret Manager
4. **CDN**: Add Cloud CDN for better performance
5. **Authentication**: Add Cloud IAM for service-to-service auth

## Support

- Cloud Run docs: https://cloud.google.com/run/docs
- Terraform docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- MongoDB Atlas: https://docs.atlas.mongodb.com/
