# Educational App - Cloud Run Deployment Script
# This script automates the deployment to Google Cloud Run

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$true)]
    [string]$MongoDbUri,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-central1"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Educational App - Cloud Run Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set project
Write-Host "Setting GCP project to: $ProjectId" -ForegroundColor Yellow
gcloud config set project $ProjectId

# Enable required APIs
Write-Host "`nEnabling required APIs..." -ForegroundColor Yellow
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# Create Artifact Registry repository
Write-Host "`nCreating Artifact Registry repository..." -ForegroundColor Yellow
gcloud artifacts repositories create educational-app `
    --repository-format=docker `
    --location=$Region `
    --description="Docker repository for educational app" `
    2>$null

# Configure Docker authentication
Write-Host "`nConfiguring Docker authentication..." -ForegroundColor Yellow
gcloud auth configure-docker ${Region}-docker.pkg.dev

# Build and push Docker images
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Building and Pushing Docker Images" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$services = @("auth-service", "learning-service", "payment-service", "api-gateway", "frontend")

foreach ($service in $services) {
    Write-Host "`nBuilding $service..." -ForegroundColor Green
    $imageName = "${Region}-docker.pkg.dev/${ProjectId}/educational-app/${service}:latest"
    
    docker build -t $imageName "./$service"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Pushing $service..." -ForegroundColor Green
        docker push $imageName
    } else {
        Write-Host "Failed to build $service" -ForegroundColor Red
        exit 1
    }
}

# Create terraform.tfvars
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Configuring Terraform" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$tfvarsContent = @"
project_id  = "$ProjectId"
region      = "$Region"
mongodb_uri = "$MongoDbUri"
github_repo = "AllanDzingo/educational-app"
"@

Set-Content -Path "terraform/cloud-run/terraform.tfvars" -Value $tfvarsContent
Write-Host "Created terraform.tfvars" -ForegroundColor Green

# Deploy with Terraform
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deploying with Terraform" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Set-Location "terraform/cloud-run"

Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init

Write-Host "`nPlanning deployment..." -ForegroundColor Yellow
terraform plan

Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
terraform apply -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Deployment Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Your application URLs:" -ForegroundColor Cyan
    terraform output
    
    Write-Host "`nTo view logs:" -ForegroundColor Yellow
    Write-Host "gcloud run services logs read SERVICE_NAME --region=$Region" -ForegroundColor White
    
    Write-Host "`nTo update your app:" -ForegroundColor Yellow
    Write-Host "1. Make changes to your code" -ForegroundColor White
    Write-Host "2. Run this script again" -ForegroundColor White
    Write-Host "   OR" -ForegroundColor White
    Write-Host "3. Set up CI/CD with: gcloud builds triggers create github ..." -ForegroundColor White
} else {
    Write-Host "`nDeployment failed. Check the errors above." -ForegroundColor Red
    exit 1
}

Set-Location ../..
