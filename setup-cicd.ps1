# Setup CI/CD Pipeline for Educational App
# This script sets up the multi-environment CI/CD pipeline

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory = $true)]
    [string]$MongoDbUriTest,
    
    [Parameter(Mandatory = $true)]
    [string]$MongoDbUriProd,
    
    [Parameter(Mandatory = $false)]
    [string]$Region = "us-central1",
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubOwner = "AllanDzingo",
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubRepo = "educational-app"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CI/CD Pipeline Setup" -ForegroundColor Cyan
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
gcloud services enable secretmanager.googleapis.com

# Create Artifact Registry repository
Write-Host "`nCreating Artifact Registry repository..." -ForegroundColor Yellow
gcloud artifacts repositories create educational-app `
    --repository-format=docker `
    --location=$Region `
    --description="Docker repository for educational app" `
    2>$null

# Create Cloud Storage bucket for test results
Write-Host "`nCreating Cloud Storage bucket for test results..." -ForegroundColor Yellow
gsutil mb -p $ProjectId -l $Region gs://${ProjectId}_cloudbuild 2>$null

# Store MongoDB URIs in Secret Manager
Write-Host "`nStoring MongoDB URIs in Secret Manager..." -ForegroundColor Yellow

# Test MongoDB URI
Write-Output $MongoDbUriTest | gcloud secrets create mongodb-uri-test `
    --data-file=- `
    --replication-policy="automatic" `
    2>$null

# Production MongoDB URI
Write-Output $MongoDbUriProd | gcloud secrets create mongodb-uri-prod `
    --data-file=- `
    --replication-policy="automatic" `
    2>$null

# Grant Cloud Build access to secrets
Write-Host "`nGranting Cloud Build access to secrets..." -ForegroundColor Yellow
$projectNumber = (gcloud projects describe $ProjectId --format="value(projectNumber)")
$cloudBuildSA = "${projectNumber}@cloudbuild.gserviceaccount.com"

gcloud secrets add-iam-policy-binding mongodb-uri-test `
    --member="serviceAccount:$cloudBuildSA" `
    --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding mongodb-uri-prod `
    --member="serviceAccount:$cloudBuildSA" `
    --role="roles/secretmanager.secretAccessor"

# Update Postman environment files with project ID
Write-Host "`nUpdating Postman environment files..." -ForegroundColor Yellow

$testEnvPath = "tests/postman/environment-test.json"
$prodEnvPath = "tests/postman/environment-prod.json"

if (Test-Path $testEnvPath) {
    (Get-Content $testEnvPath) -replace 'PROJECT_ID', $ProjectId | Set-Content $testEnvPath
    Write-Host "Updated $testEnvPath" -ForegroundColor Green
}

if (Test-Path $prodEnvPath) {
    (Get-Content $prodEnvPath) -replace 'PROJECT_ID', $ProjectId | Set-Content $prodEnvPath
    Write-Host "Updated $prodEnvPath" -ForegroundColor Green
}

# Create Cloud Build trigger
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Creating Cloud Build Trigger" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nConnecting to GitHub repository..." -ForegroundColor Yellow
Write-Host "You may need to authorize Cloud Build to access your GitHub repository." -ForegroundColor Yellow
Write-Host ""

gcloud builds triggers create github `
    --name="educational-app-cicd" `
    --repo-name=$GitHubRepo `
    --repo-owner=$GitHubOwner `
    --branch-pattern="^main$" `
    --build-config=cloudbuild.yaml `
    --substitutions="_REGION=$Region,_MONGODB_URI_TEST=$MongoDbUriTest,_MONGODB_URI_PROD=$MongoDbUriProd"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "CI/CD Pipeline Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "✅ Enabled required APIs" -ForegroundColor Green
    Write-Host "✅ Created Artifact Registry" -ForegroundColor Green
    Write-Host "✅ Created Cloud Storage bucket" -ForegroundColor Green
    Write-Host "✅ Stored MongoDB URIs in Secret Manager" -ForegroundColor Green
    Write-Host "✅ Updated Postman environment files" -ForegroundColor Green
    Write-Host "✅ Created Cloud Build trigger" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Push your code to GitHub:" -ForegroundColor White
    Write-Host "   git add ." -ForegroundColor Gray
    Write-Host "   git commit -m 'Set up CI/CD pipeline'" -ForegroundColor Gray
    Write-Host "   git push origin main" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Monitor the build:" -ForegroundColor White
    Write-Host "   https://console.cloud.google.com/cloud-build/builds?project=$ProjectId" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. View your services:" -ForegroundColor White
    Write-Host "   Test: https://console.cloud.google.com/run?project=$ProjectId" -ForegroundColor Gray
    Write-Host "   Prod: https://console.cloud.google.com/run?project=$ProjectId" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Pipeline Workflow:" -ForegroundColor Cyan
    Write-Host "  Push to GitHub → Build Images → Deploy to TEST → Run Tests → Deploy to PROD" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Documentation:" -ForegroundColor Cyan
    Write-Host "  See CI-CD-GUIDE.md for detailed information" -ForegroundColor White
    
}
else {
    Write-Host "`nSetup encountered errors. Please check the messages above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "- GitHub repository not connected: Visit https://console.cloud.google.com/cloud-build/triggers" -ForegroundColor White
    Write-Host "- Billing not enabled: Visit https://console.cloud.google.com/billing" -ForegroundColor White
    Write-Host "- APIs not enabled: Run 'gcloud services enable ...' manually" -ForegroundColor White
    exit 1
}
