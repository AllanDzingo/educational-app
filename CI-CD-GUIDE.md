# Multi-Environment CI/CD Pipeline Guide

## Overview

This guide explains the automated CI/CD pipeline that deploys your Educational App to **Test** and **Production** environments with automated health checks and integration tests.

## Pipeline Workflow

```
┌─────────────────┐
│  Push to GitHub │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Build Images   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Deploy to TEST │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Health Checks  │ ◄── Newman/Postman Tests
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Integration     │ ◄── Newman/Postman Tests
│ Tests           │
└────────┬────────┘
         │
         ▼
    ┌───────┐
    │ Pass? │
    └───┬───┘
        │ Yes
        ▼
┌─────────────────┐
│ Deploy to PROD  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Smoke Tests     │ ◄── Newman/Postman Tests
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Canary Deploy   │ (10% → 100%)
└─────────────────┘
```

## Environments

### Test Environment
- **Purpose**: Validate changes before production
- **Services**:
  - `auth-service-test`
  - `learning-service-test`
  - `payment-service-test`
  - `api-gateway-test`
  - `frontend-test`
- **MongoDB**: Separate test database
- **Auto-deploy**: Every push to `main` branch

### Production Environment
- **Purpose**: Live application
- **Services**:
  - `auth-service-prod`
  - `learning-service-prod`
  - `payment-service-prod`
  - `api-gateway-prod`
  - `frontend-prod`
- **MongoDB**: Production database
- **Deploy**: Only after test environment passes all checks

## Setup Instructions

### 1. Set Up MongoDB Databases

Create two MongoDB Atlas clusters (or use separate databases):

**Test Database:**
```
mongodb+srv://user:pass@cluster-test.mongodb.net/educational-app-test
```

**Production Database:**
```
mongodb+srv://user:pass@cluster-prod.mongodb.net/educational-app-prod
```

### 2. Configure Cloud Build Trigger

```bash
# Create Cloud Build trigger
gcloud builds triggers create github \
  --repo-name=educational-app \
  --repo-owner=AllanDzingo \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml \
  --substitutions=_MONGODB_URI_TEST="mongodb+srv://...",_MONGODB_URI_PROD="mongodb+srv://..."
```

### 3. Set Up Substitution Variables

In Google Cloud Console → Cloud Build → Triggers → Edit Trigger:

Add substitutions:
- `_MONGODB_URI_TEST`: Your test MongoDB URI
- `_MONGODB_URI_PROD`: Your production MongoDB URI
- `_REGION`: `us-central1` (or your preferred region)

### 4. Update Postman Environment Files

Edit the environment files with your actual project ID:

**tests/postman/environment-test.json:**
```json
{
  "name": "Test Environment",
  "values": [
    {
      "key": "API_GATEWAY_URL",
      "value": "https://api-gateway-test-YOUR_PROJECT_ID.run.app",
      "enabled": true
    }
    // ... other services
  ]
}
```

**tests/postman/environment-prod.json:**
```json
{
  "name": "Production Environment",
  "values": [
    {
      "key": "API_GATEWAY_URL",
      "value": "https://api-gateway-prod-YOUR_PROJECT_ID.run.app",
      "enabled": true
    }
    // ... other services
  ]
}
```

## Testing

### Health Check Endpoints

All services have `/health` endpoints:

**Auth Service:**
```bash
curl https://auth-service-test-PROJECT_ID.run.app/health
```

Response:
```json
{
  "status": "healthy",
  "service": "auth-service",
  "timestamp": "2025-01-26T12:00:00.000Z",
  "database": "connected",
  "environment": "test"
}
```

**API Gateway:**
```bash
curl https://api-gateway-test-PROJECT_ID.run.app/health
```

Response:
```json
{
  "status": "healthy",
  "service": "api-gateway",
  "timestamp": "2025-01-26T12:00:00.000Z",
  "environment": "test",
  "services": {
    "auth": "healthy",
    "learning": "healthy",
    "payment": "healthy"
  }
}
```

### Running Tests Locally

Install Newman (Postman CLI):
```bash
npm install -g newman
```

Run health checks:
```bash
newman run tests/postman/educational-app-tests.json \
  --environment tests/postman/environment-test.json \
  --folder "Health Checks"
```

Run integration tests:
```bash
newman run tests/postman/educational-app-tests.json \
  --environment tests/postman/environment-test.json \
  --folder "Integration Tests"
```

## Deployment Process

### Automatic Deployment (Recommended)

1. **Make changes** to your code
2. **Commit and push** to GitHub:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```
3. **Cloud Build automatically**:
   - Builds Docker images
   - Deploys to test environment
   - Runs health checks
   - Runs integration tests
   - If tests pass, deploys to production
   - Performs canary deployment (10% → 100%)

### Manual Deployment

Deploy to test environment:
```bash
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_MONGODB_URI_TEST="...",_MONGODB_URI_PROD="..."
```

## Monitoring Deployments

### View Build Logs

```bash
# List recent builds
gcloud builds list --limit=10

# View specific build
gcloud builds log BUILD_ID
```

### View Service Logs

```bash
# Test environment
gcloud run services logs read auth-service-test --region=us-central1

# Production environment
gcloud run services logs read auth-service-prod --region=us-central1
```

### View Test Results

Test results are stored as artifacts in Cloud Storage:
```
gs://PROJECT_ID_cloudbuild/test-results/BUILD_ID/
├── test-results.json
├── integration-results.json
└── prod-smoke-results.json
```

Download test results:
```bash
gsutil cp gs://PROJECT_ID_cloudbuild/test-results/BUILD_ID/*.json ./
```

## Canary Deployment

The pipeline uses canary deployment for production:

1. **Deploy new version** with no traffic
2. **Run smoke tests** on new version
3. **Shift 10% traffic** to new version
4. **Wait 60 seconds** to monitor
5. **Shift 100% traffic** if no errors

### Manual Traffic Control

Shift traffic manually:
```bash
# Shift 50% to new version
gcloud run services update-traffic auth-service-prod \
  --to-revisions=REVISION_NAME=50 \
  --region=us-central1

# Shift 100% to latest
gcloud run services update-traffic auth-service-prod \
  --to-latest \
  --region=us-central1
```

## Rollback

If issues are detected in production:

### Automatic Rollback

```bash
# Rollback to previous revision
gcloud run services update-traffic auth-service-prod \
  --to-revisions=PREVIOUS_REVISION=100 \
  --region=us-central1
```

### List Revisions

```bash
gcloud run revisions list \
  --service=auth-service-prod \
  --region=us-central1
```

## Environment Variables

### Test Environment
- `ENVIRONMENT=test`
- `MONGODB_URI=${_MONGODB_URI_TEST}`
- `AUTH_SERVICE_URL=https://auth-service-test-PROJECT_ID.run.app`
- `LEARNING_SERVICE_URL=https://learning-service-test-PROJECT_ID.run.app`
- `PAYMENT_SERVICE_URL=https://payment-service-test-PROJECT_ID.run.app`

### Production Environment
- `ENVIRONMENT=production`
- `MONGODB_URI=${_MONGODB_URI_PROD}`
- `AUTH_SERVICE_URL=https://auth-service-prod-PROJECT_ID.run.app`
- `LEARNING_SERVICE_URL=https://learning-service-prod-PROJECT_ID.run.app`
- `PAYMENT_SERVICE_URL=https://payment-service-prod-PROJECT_ID.run.app`

## Adding New Tests

### 1. Update Postman Collection

Edit `tests/postman/educational-app-tests.json`:

```json
{
  "name": "New Test",
  "event": [
    {
      "listen": "test",
      "script": {
        "exec": [
          "pm.test('Test description', function () {",
          "    pm.response.to.have.status(200);",
          "});"
        ]
      }
    }
  ],
  "request": {
    "method": "GET",
    "url": "{{API_GATEWAY_URL}}/endpoint"
  }
}
```

### 2. Test Locally

```bash
newman run tests/postman/educational-app-tests.json \
  --environment tests/postman/environment-test.json
```

### 3. Commit and Push

The new tests will run automatically on next deployment.

## Troubleshooting

### Tests Failing

1. **Check test results**:
   ```bash
   gsutil cat gs://PROJECT_ID_cloudbuild/test-results/BUILD_ID/test-results.json
   ```

2. **View service logs**:
   ```bash
   gcloud run services logs read SERVICE_NAME-test --region=us-central1
   ```

3. **Test manually**:
   ```bash
   curl https://SERVICE_NAME-test-PROJECT_ID.run.app/health
   ```

### Deployment Stuck

1. **Check build status**:
   ```bash
   gcloud builds list --ongoing
   ```

2. **Cancel build**:
   ```bash
   gcloud builds cancel BUILD_ID
   ```

3. **Re-trigger**:
   ```bash
   git commit --allow-empty -m "Trigger rebuild"
   git push origin main
   ```

### Production Issues

1. **Immediate rollback**:
   ```bash
   gcloud run services update-traffic SERVICE_NAME-prod \
     --to-revisions=PREVIOUS_REVISION=100 \
     --region=us-central1
   ```

2. **Check logs**:
   ```bash
   gcloud run services logs read SERVICE_NAME-prod --region=us-central1 --limit=100
   ```

## Best Practices

1. **Always test locally** before pushing
2. **Monitor test environment** after deployment
3. **Review test results** before production deployment
4. **Use canary deployments** for gradual rollout
5. **Keep test data separate** from production
6. **Monitor production metrics** after deployment
7. **Have rollback plan** ready

## Cost Optimization

- **Test environment**: Scales to zero when not in use
- **Production environment**: Set minimum instances based on traffic
- **Delete old revisions**: Keep only last 5-10 revisions

```bash
# Delete old revisions
gcloud run revisions delete REVISION_NAME --region=us-central1
```

## Next Steps

1. Set up monitoring and alerting
2. Add more comprehensive integration tests
3. Implement load testing
4. Set up custom domains
5. Add authentication to services
6. Implement rate limiting
7. Set up CDN for frontend

## Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Newman Documentation](https://learning.postman.com/docs/running-collections/using-newman-cli/command-line-integration-with-newman/)
- [Postman Documentation](https://learning.postman.com/docs/getting-started/introduction/)
