# Kyverno Policy Testing and Validation Guide

## Overview

This guide explains how to install Kyverno, apply policies, and test Kubernetes manifests in the test environment before deploying to production.

---

## What is Kyverno?

Kyverno is a policy engine designed for Kubernetes. It can:
- **Validate** resources against policies
- **Mutate** resources to comply with policies
- **Generate** resources based on triggers

---

## Policies Implemented

### 1. Require Minimum Replicas
**File**: `k8s/kyverno-policies/require-min-replicas.yaml`

**Purpose**: Ensures all Deployments have at least 2 replicas for high availability

**Actions**:
- **Validates**: Checks if replicas >= 2
- **Mutates**: Automatically sets replicas to 2 if less than 2

### 2. Add Team Label
**File**: `k8s/kyverno-policies/add-team-label.yaml`

**Purpose**: Adds `team: edu-app` label to all resources for organization

**Actions**:
- **Mutates**: Adds team label to Deployments and Services
- **Validates**: Ensures team label exists

---

## Installation

### Install Kyverno on Minikube

```bash
# Start Minikube
minikube start

# Install Kyverno using Helm
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace

# Verify installation
kubectl get pods -n kyverno
```

### Alternative: Install with kubectl

```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.11.0/install.yaml
```

---

## Apply Policies

### Apply All Policies

```bash
# Apply minimum replicas policy
kubectl apply -f k8s/kyverno-policies/require-min-replicas.yaml

# Apply team label policy
kubectl apply -f k8s/kyverno-policies/add-team-label.yaml

# Verify policies are installed
kubectl get clusterpolicies
```

Expected output:
```
NAME                   BACKGROUND   ACTION   READY
add-team-label         true         audit    true
require-min-replicas   true         audit    true
```

---

## Testing Policies

### Test 1: Validate Existing Manifests

Test if your manifests comply with policies:

```bash
# Test auth-service
kubectl apply -f k8s/auth-service.yaml --dry-run=server

# Test all services
kubectl apply -f k8s/ --dry-run=server
```

### Test 2: Test Policy Mutation

Create a test deployment with 1 replica:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx
EOF
```

Check if it was mutated to 2 replicas:

```bash
kubectl get deployment test-deployment -o yaml | grep replicas
```

Expected: `replicas: 2`

### Test 3: Verify Team Labels

Check if team labels were added:

```bash
kubectl get deployment test-deployment -o yaml | grep "team:"
```

Expected: `team: edu-app`

### Test 4: Policy Reports

View policy violations and mutations:

```bash
# View policy reports
kubectl get policyreport -A

# View cluster policy reports
kubectl get clusterpolicyreport

# Describe a specific report
kubectl describe policyreport -n default
```

---

## Integration with CI/CD

### Add Kyverno Testing to Cloud Build

Update `cloudbuild.yaml` to include Kyverno validation:

```yaml
# Add this step before deploying to test environment
- name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
  id: 'validate-k8s-with-kyverno'
  entrypoint: 'bash'
  args:
    - '-c'
    - |
      # Install kubectl
      gcloud components install kubectl
      
      # Install Kyverno CLI
      curl -LO https://github.com/kyverno/kyverno/releases/download/v1.11.0/kyverno-cli_v1.11.0_linux_x86_64.tar.gz
      tar -xzf kyverno-cli_v1.11.0_linux_x86_64.tar.gz
      chmod +x kyverno
      
      # Apply policies
      ./kyverno apply k8s/kyverno-policies/ --resource k8s/ --policy-report
      
      # Check for policy violations
      if [ $? -ne 0 ]; then
        echo "Policy violations detected!"
        exit 1
      fi
```

### Kyverno CLI Testing (Local)

Install Kyverno CLI:

```bash
# Download Kyverno CLI
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.11.0/kyverno-cli_v1.11.0_windows_x86_64.zip

# Extract and add to PATH
```

Test policies locally:

```bash
# Test all policies against all manifests
kyverno apply k8s/kyverno-policies/ --resource k8s/

# Test specific policy
kyverno apply k8s/kyverno-policies/require-min-replicas.yaml --resource k8s/auth-service.yaml

# Generate policy report
kyverno apply k8s/kyverno-policies/ --resource k8s/ --policy-report
```

---

## Deployment Workflow with Kyverno

```
┌─────────────────────┐
│  Developer creates  │
│  K8s manifest       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Test locally with  │
│  Kyverno CLI        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Push to GitHub     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Cloud Build runs   │
│  Kyverno validation │
└──────────┬──────────┘
           │
           ▼
      ┌────────┐
      │ Valid? │
      └────┬───┘
           │ YES
           ▼
┌─────────────────────┐
│  Deploy to TEST     │
│  environment        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Kyverno policies   │
│  enforce rules      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Deploy to PROD     │
└─────────────────────┘
```

---

## Policy Examples

### Current Policies

#### Minimum Replicas Policy
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-min-replicas
spec:
  rules:
    - name: validate-min-replicas
      validate:
        message: "Deployments must have at least 2 replicas"
        pattern:
          spec:
            replicas: ">=2"
    - name: mutate-min-replicas
      mutate:
        patchStrategicMerge:
          spec:
            replicas: 2
```

#### Team Label Policy
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-team-label
spec:
  rules:
    - name: add-team-label-deployment
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              team: edu-app
```

---

## Monitoring and Reporting

### View Policy Violations

```bash
# Get all policy reports
kubectl get policyreport -A

# View detailed report
kubectl get policyreport -n default -o yaml

# Count violations
kubectl get policyreport -A -o json | jq '.items[].results[] | select(.result=="fail")' | wc -l
```

### Policy Metrics

Kyverno exposes Prometheus metrics:

```bash
# Port-forward to Kyverno metrics
kubectl port-forward -n kyverno svc/kyverno-svc-metrics 8000:8000

# View metrics
curl http://localhost:8000/metrics
```

---

## Best Practices

### 1. Test Policies Locally First
Always test policies with Kyverno CLI before applying to cluster

### 2. Use Audit Mode Initially
Set `validationFailureAction: audit` to monitor without blocking

### 3. Gradual Rollout
- Start with audit mode
- Review policy reports
- Switch to enforce mode when confident

### 4. Document Policies
Add clear descriptions and examples to policy annotations

### 5. Version Control
Keep policies in Git alongside manifests

---

## Troubleshooting

### Policy Not Applied

```bash
# Check policy status
kubectl get clusterpolicy require-min-replicas -o yaml

# Check Kyverno logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno
```

### Mutation Not Working

```bash
# Verify policy is in mutate mode
kubectl get clusterpolicy add-team-label -o jsonpath='{.spec.rules[*].mutate}'

# Check if resource was mutated
kubectl get deployment DEPLOYMENT_NAME -o yaml
```

### Policy Violations

```bash
# View policy report
kubectl describe policyreport -n NAMESPACE

# Check specific resource
kubectl get deployment DEPLOYMENT_NAME -o yaml | grep -A 5 "kyverno"
```

---

## Additional Policies (Optional)

### Require Resource Limits

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  rules:
    - name: validate-resources
      validate:
        message: "Containers must have resource limits"
        pattern:
          spec:
            containers:
            - resources:
                limits:
                  memory: "?*"
                  cpu: "?*"
```

### Disallow Latest Tag

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  rules:
    - name: require-image-tag
      validate:
        message: "Using 'latest' tag is not allowed"
        pattern:
          spec:
            containers:
            - image: "!*:latest"
```

---

## Summary

✅ **Kyverno installed** on Minikube
✅ **Policies applied** for minimum replicas and team labels
✅ **All manifests updated** with team labels and 2 replicas
✅ **Testing workflow** integrated with CI/CD
✅ **Validation** before deployment to production

### Quick Commands

```bash
# Install Kyverno
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# Apply policies
kubectl apply -f k8s/kyverno-policies/

# Test locally
kyverno apply k8s/kyverno-policies/ --resource k8s/

# View reports
kubectl get policyreport -A

# Deploy with validation
kubectl apply -f k8s/ --dry-run=server
```

---

## Resources

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Policies Library](https://kyverno.io/policies/)
- [Kyverno CLI](https://kyverno.io/docs/kyverno-cli/)
- [Policy Samples](https://github.com/kyverno/policies)
