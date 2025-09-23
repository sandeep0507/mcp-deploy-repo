# 🚀 GitHub Actions + ArgoCD GitOps Workflow

## Overview

This GitHub Actions workflow provides **automated GitOps deployment** that triggers ArgoCD synchronization when changes are pushed to the remote repository. It's a more robust alternative to local monitoring and provides better integration with CI/CD pipelines.

## 🎯 Features

- **🔄 Automatic Triggers**: Deploys on push to main branch
- **📊 Smart Change Detection**: Only deploys changed applications
- **☁️ Cloud-Native**: Runs in GitHub Actions runners
- **🔗 ArgoCD Integration**: Syncs with ArgoCD applications
- **🛡️ Environment Support**: Supports multiple environments
- **📝 Comprehensive Logging**: Detailed deployment logs and summaries

## 📁 Files Created

- `.github/workflows/argocd-deploy.yml` - Main GitHub Actions workflow
- `scripts/github-argocd-sync.sh` - Deployment script for GitHub Actions
- `GITHUB-ACTIONS-ARGOCD-README.md` - This documentation

## 🛠️ Setup Instructions

### 1. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

```bash
# Go to: Settings > Secrets and variables > Actions > Repository secrets

# Kubernetes Configuration (Base64 encoded kubeconfig)
KUBECONFIG=<base64-encoded-kubeconfig>

# ArgoCD Configuration (Optional)
ARGOCD_SERVER=https://argocd.your-domain.com
ARGOCD_TOKEN=<argocd-api-token>
```

### 2. Generate KUBECONFIG Secret

```bash
# Export your kubeconfig
kubectl config view --raw > kubeconfig.yaml

# Base64 encode it
base64 -i kubeconfig.yaml -o kubeconfig.b64

# Copy the content and add it as KUBECONFIG secret in GitHub
cat kubeconfig.b64
```

### 3. Generate ArgoCD Token (Optional)

```bash
# Login to ArgoCD
argocd login <argocd-server>

# Create a token
argocd account generate-token --account <username>
```

## 🔄 How It Works

### Workflow Triggers

The workflow triggers on:
- **Push to main branch** with changes to `helm/**` or `k8s/**`
- **Pull requests** to main branch
- **Manual dispatch** with environment selection

### Change Detection

The workflow uses `dorny/paths-filter` to detect changes:
- `helm/redis/**` → Deploy Redis
- `helm/mcp-server/**` → Deploy MCP Server  
- `helm/gitops-monitor/**` → Deploy GitOps Monitor

### Deployment Process

1. **Detect Changes**: Identify which applications changed
2. **Deploy with Helm**: Use Helm to upgrade/install applications
3. **Verify Deployment**: Wait for pods to be ready
4. **Sync ArgoCD**: Trigger ArgoCD synchronization
5. **Generate Summary**: Create deployment summary

## 📊 Workflow Jobs

### 1. `detect-changes`
- Checks which applications have changed
- Sets job outputs for conditional deployment

### 2. `deploy-redis`
- Deploys Redis if `helm/redis/**` changed
- Verifies deployment success

### 3. `deploy-mcp-server`
- Deploys MCP Server if `helm/mcp-server/**` changed
- Verifies deployment success

### 4. `deploy-gitops-monitor`
- Deploys GitOps Monitor if `helm/gitops-monitor/**` changed
- Verifies deployment success

### 5. `argocd-sync`
- Syncs all applications with ArgoCD
- Provides fallback if ArgoCD is not configured

### 6. `notify`
- Generates deployment summary
- Shows in GitHub Actions UI

## 🧪 Testing the Workflow

### 1. Make a Change

```bash
# Edit Redis configuration
vim helm/redis/values.yaml
# Change replicaCount from 7 to 8
```

### 2. Commit and Push

```bash
git add helm/redis/values.yaml
git commit -m "feat: Scale Redis to 8 replicas"
git push origin main
```

### 3. Watch GitHub Actions

1. Go to your GitHub repository
2. Click on "Actions" tab
3. Watch the "ArgoCD Deploy" workflow run
4. Check the deployment summary

### 4. Verify Deployment

```bash
# Check Redis pods
kubectl get pods -n redis-prod

# Check deployment status
kubectl get deployment redis -n redis-prod
```

## 🔧 Configuration Options

### Environment Selection

The workflow supports multiple environments:

```yaml
# Manual dispatch with environment selection
workflow_dispatch:
  inputs:
    environment:
      description: 'Environment to deploy to'
      required: true
      default: 'minikube'
      type: choice
      options:
        - minikube
        - staging
        - production
```

### Custom Values

You can customize deployments by modifying the Helm commands:

```yaml
# Example: Custom values file
helm upgrade --install redis ./helm/redis \
  --namespace redis-prod \
  --create-namespace \
  --values custom-values.yaml \
  --set namespace=redis-prod
```

## 📝 Workflow Examples

### Basic Deployment

```yaml
# Triggers on any push to main
on:
  push:
    branches: [ main ]
    paths:
      - 'helm/**'
```

### Environment-Specific Deployment

```yaml
# Different environments with different configurations
- name: Deploy to staging
  if: github.ref == 'refs/heads/staging'
  run: |
    helm upgrade --install redis ./helm/redis \
      --namespace redis-staging \
      --values helm/redis/values-staging.yaml
```

### Conditional Deployment

```yaml
# Only deploy if specific files changed
- name: Deploy Redis
  if: contains(github.event.head_commit.modified, 'helm/redis/')
  run: |
    helm upgrade --install redis ./helm/redis
```

## 🚨 Troubleshooting

### Common Issues

1. **KUBECONFIG Invalid**
   ```
   Error: Cannot connect to Kubernetes cluster
   ```
   - Check if KUBECONFIG secret is properly base64 encoded
   - Verify the kubeconfig has correct cluster context

2. **ArgoCD Sync Failed**
   ```
   Failed to sync redis-gitops-app with ArgoCD
   ```
   - Check ARGOCD_SERVER and ARGOCD_TOKEN secrets
   - Verify ArgoCD application exists

3. **Helm Deployment Timeout**
   ```
   Error: release redis failed to become ready
   ```
   - Check resource limits and requests
   - Verify image availability
   - Check pod logs for errors

### Debug Commands

```bash
# Check workflow logs
gh run list --workflow="ArgoCD Deploy"
gh run view <run-id>

# Check cluster status
kubectl get pods --all-namespaces
kubectl get events --sort-by='.lastTimestamp'

# Check ArgoCD status
kubectl get applications -n argocd
argocd app get redis-gitops-app
```

## 🔐 Security Considerations

### Secrets Management

- **KUBECONFIG**: Contains cluster access credentials
- **ARGOCD_TOKEN**: Provides ArgoCD API access
- **Repository Secrets**: Stored encrypted in GitHub

### RBAC Requirements

The workflow needs the following permissions:
- **Deploy applications** in target namespaces
- **Create namespaces** if they don't exist
- **Read pod status** for verification
- **Sync ArgoCD applications** (if configured)

### Network Access

- **GitHub Actions runners** need access to your Kubernetes cluster
- **ArgoCD server** needs to be accessible from GitHub Actions
- **Container registries** need to be accessible for image pulls

## 📈 Benefits

1. **🔄 Fully Automated**: No manual intervention required
2. **☁️ Cloud-Native**: Runs in GitHub's infrastructure
3. **🔗 GitOps Integration**: Seamless ArgoCD synchronization
4. **📊 Visibility**: Clear deployment status and logs
5. **🛡️ Reliable**: Robust error handling and recovery
6. **🔧 Flexible**: Supports multiple environments and configurations

## 🎯 Use Cases

- **Development**: Automatic deployment of development changes
- **Staging**: Continuous integration with staging environment
- **Production**: Automated production deployments with approvals
- **Multi-Environment**: Deploy to different environments based on branch
- **Rollback**: Easy rollback through Git history

---

## 🎉 Success!

Your GitHub Actions + ArgoCD GitOps workflow is now configured! Any changes you make to the `helm/` directory will automatically trigger deployment through GitHub Actions and sync with ArgoCD.

**Next Steps:**
1. Configure GitHub secrets
2. Test the workflow with a small change
3. Monitor deployments in GitHub Actions
4. Set up ArgoCD applications for better visibility
5. Configure notifications for deployment status
