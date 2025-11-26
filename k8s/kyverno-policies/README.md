# Kyverno Policies

This directory contains Kyverno policies for validating and mutating Kubernetes resources.

## Policies

### 1. require-min-replicas.yaml
**Purpose**: Ensure high availability by requiring minimum 2 replicas for all Deployments

**Actions**:
- Validates that `spec.replicas >= 2`
- Automatically mutates Deployments with < 2 replicas to have 2 replicas

**Example**:
```yaml
# Before mutation
spec:
  replicas: 1

# After mutation
spec:
  replicas: 2
```

### 2. add-team-label.yaml
**Purpose**: Add team label for resource organization and tracking

**Actions**:
- Adds `team: edu-app` label to all Deployments and Services
- Validates that team label exists

**Example**:
```yaml
# Labels added automatically
metadata:
  labels:
    team: edu-app
```

## Installation

```bash
# Install Kyverno
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace

# Apply policies
kubectl apply -f k8s/kyverno-policies/
```

## Testing

```bash
# Test with Kyverno CLI
kyverno apply k8s/kyverno-policies/ --resource k8s/

# Test with kubectl dry-run
kubectl apply -f k8s/ --dry-run=server

# View policy reports
kubectl get policyreport -A
```

## Documentation

See [KYVERNO-GUIDE.md](../../KYVERNO-GUIDE.md) for complete documentation.
