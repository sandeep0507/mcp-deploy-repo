#!/bin/bash

# GitHub Actions ArgoCD Sync Script
# This script handles ArgoCD synchronization triggered by GitHub Actions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ARGOCD_SERVER="${ARGOCD_SERVER:-}"
ARGOCD_TOKEN="${ARGOCD_TOKEN:-}"
KUBECONFIG_FILE="${KUBECONFIG:-}"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        error "helm is not installed"
        exit 1
    fi
    
    if [ -n "$KUBECONFIG_FILE" ]; then
        log "Setting up kubectl configuration..."
        echo "$KUBECONFIG_FILE" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig
    fi
    
    # Test kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Deploy application with Helm
deploy_with_helm() {
    local app_name="$1"
    local chart_path="$2"
    local namespace="$3"
    local values_file="${4:-}"
    
    log "Deploying $app_name with Helm..."
    
    local helm_cmd="helm upgrade --install $app_name $chart_path --namespace $namespace --create-namespace"
    
    if [ -n "$values_file" ] && [ -f "$values_file" ]; then
        helm_cmd="$helm_cmd --values $values_file"
    fi
    
    # Add namespace setting if specified
    if [ -n "$namespace" ]; then
        helm_cmd="$helm_cmd --set namespace=$namespace"
    fi
    
    # Add wait and timeout
    helm_cmd="$helm_cmd --wait --timeout=5m"
    
    log "Running: $helm_cmd"
    eval $helm_cmd
    
    success "$app_name deployed successfully"
}

# Verify deployment
verify_deployment() {
    local app_name="$1"
    local namespace="$2"
    local label_selector="$3"
    
    log "Verifying $app_name deployment..."
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l "$label_selector" -n "$namespace" --timeout=300s || {
        warning "Pods not ready within timeout, showing current status:"
        kubectl get pods -n "$namespace" -l "$label_selector"
        return 1
    }
    
    # Show pod status
    kubectl get pods -n "$namespace" -l "$label_selector"
    
    # Show deployment status
    kubectl get deployment "$app_name" -n "$namespace" || true
    
    success "$app_name verification completed"
}

# Sync with ArgoCD
sync_argocd() {
    local app_name="$1"
    
    if [ -z "$ARGOCD_SERVER" ] || [ -z "$ARGOCD_TOKEN" ]; then
        warning "ArgoCD not configured, skipping sync for $app_name"
        return 0
    fi
    
    log "Syncing $app_name with ArgoCD..."
    
    local sync_url="$ARGOCD_SERVER/api/v1/applications/$app_name/sync"
    
    curl -X POST "$sync_url" \
        -H "Authorization: Bearer $ARGOCD_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"prune": true, "dryRun": false}' || {
        error "Failed to sync $app_name with ArgoCD"
        return 1
    }
    
    success "$app_name synced with ArgoCD"
}

# Main deployment function
deploy_application() {
    local app_name="$1"
    local chart_path="$2"
    local namespace="$3"
    local label_selector="$4"
    local values_file="${5:-}"
    
    log "Starting deployment of $app_name..."
    
    # Deploy with Helm
    deploy_with_helm "$app_name" "$chart_path" "$namespace" "$values_file"
    
    # Verify deployment
    verify_deployment "$app_name" "$namespace" "$label_selector"
    
    # Sync with ArgoCD
    sync_argocd "$app_name"
    
    success "$app_name deployment completed successfully"
}

# Deploy all applications
deploy_all() {
    log "Starting deployment of all applications..."
    
    # Deploy Redis
    if [ -d "helm/redis" ]; then
        deploy_application "redis" "helm/redis" "redis-prod" "app.kubernetes.io/name=redis"
    fi
    
    # Deploy MCP Server
    if [ -d "helm/mcp-server" ]; then
        deploy_application "mcp-server" "helm/mcp-server" "mcp-server" "app.kubernetes.io/name=mcp-server"
    fi
    
    # Deploy GitOps Monitor
    if [ -d "helm/gitops-monitor" ]; then
        deploy_application "gitops-monitor" "helm/gitops-monitor" "gitops-monitor" "app.kubernetes.io/name=gitops-monitor"
    fi
    
    success "All applications deployed successfully"
}

# Show cluster status
show_status() {
    log "Cluster Status:"
    echo ""
    
    echo "=== Namespaces ==="
    kubectl get namespaces | grep -E "(redis-prod|mcp-server|gitops-monitor|argocd)" || echo "No relevant namespaces found"
    
    echo ""
    echo "=== Redis Pods ==="
    kubectl get pods -n redis-prod -l app.kubernetes.io/name=redis 2>/dev/null || echo "No Redis pods found"
    
    echo ""
    echo "=== MCP Server Pods ==="
    kubectl get pods -n mcp-server -l app.kubernetes.io/name=mcp-server 2>/dev/null || echo "No MCP Server pods found"
    
    echo ""
    echo "=== GitOps Monitor Pods ==="
    kubectl get pods -n gitops-monitor -l app.kubernetes.io/name=gitops-monitor 2>/dev/null || echo "No GitOps Monitor pods found"
    
    echo ""
    echo "=== ArgoCD Applications ==="
    kubectl get applications -n argocd 2>/dev/null || echo "No ArgoCD applications found"
}

# Main script logic
main() {
    local action="${1:-deploy-all}"
    
    case "$action" in
        "deploy-all")
            check_prerequisites
            deploy_all
            show_status
            ;;
        "deploy-redis")
            check_prerequisites
            deploy_application "redis" "helm/redis" "redis-prod" "app.kubernetes.io/name=redis"
            ;;
        "deploy-mcp-server")
            check_prerequisites
            deploy_application "mcp-server" "helm/mcp-server" "mcp-server" "app.kubernetes.io/name=mcp-server"
            ;;
        "deploy-gitops-monitor")
            check_prerequisites
            deploy_application "gitops-monitor" "helm/gitops-monitor" "gitops-monitor" "app.kubernetes.io/name=gitops-monitor"
            ;;
        "status")
            check_prerequisites
            show_status
            ;;
        "sync-argocd")
            check_prerequisites
            sync_argocd "redis-gitops-app"
            sync_argocd "mcp-server-gitops-app"
            ;;
        *)
            echo "Usage: $0 {deploy-all|deploy-redis|deploy-mcp-server|deploy-gitops-monitor|status|sync-argocd}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
