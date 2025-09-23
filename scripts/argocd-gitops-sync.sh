#!/bin/bash

# ArgoCD GitOps Sync Script
# This script monitors the Git repository and triggers ArgoCD sync

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if ArgoCD is running
check_argocd() {
    print_status "Checking ArgoCD status..."
    
    if ! kubectl get pods -n argocd | grep -q "argocd-server.*Running"; then
        print_error "ArgoCD server is not running!"
        return 1
    fi
    
    if ! kubectl get pods -n argocd | grep -q "argocd-application-controller.*Running"; then
        print_error "ArgoCD application controller is not running!"
        return 1
    fi
    
    print_success "ArgoCD is running properly"
    return 0
}

# Function to create ArgoCD Application
create_argocd_app() {
    print_status "Creating ArgoCD Application..."
    
    # Delete existing application if it exists
    kubectl delete application redis-gitops-app -n argocd --ignore-not-found=true
    
    # Create new application
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: redis-gitops-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/SKSTAE/mcp-deploy-repo
    targetRevision: HEAD
    path: helm/redis
  destination:
    server: https://kubernetes.default.svc
    namespace: redis-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
  revisionHistoryLimit: 3
EOF
    
    print_success "ArgoCD Application created"
}

# Function to force sync ArgoCD Application
force_sync() {
    print_status "Forcing ArgoCD sync..."
    
    # Add refresh annotation to trigger sync
    kubectl annotate application redis-gitops-app -n argocd argocd.argoproj.io/refresh=hard --overwrite
    
    # Wait for sync to complete
    print_status "Waiting for sync to complete..."
    sleep 30
    
    # Check application status
    kubectl get application redis-gitops-app -n argocd
}

# Function to monitor for changes
monitor_changes() {
    print_status "Starting ArgoCD GitOps monitoring..."
    print_status "Monitoring repository for changes every 60 seconds..."
    
    while true; do
        # Check for new commits
        git fetch origin
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)
        
        if [ "$LOCAL" != "$REMOTE" ]; then
            print_status "New changes detected! Syncing..."
            git pull origin main
            force_sync
        else
            print_status "No new changes detected"
        fi
        
        sleep 60
    done
}

# Main execution
case "${1:-sync}" in
    "check")
        check_argocd
        ;;
    "create")
        check_argocd && create_argocd_app
        ;;
    "sync")
        check_argocd && force_sync
        ;;
    "monitor")
        check_argocd && create_argocd_app && monitor_changes
        ;;
    *)
        echo "Usage: $0 [check|create|sync|monitor]"
        echo "  check   - Check if ArgoCD is running"
        echo "  create  - Create ArgoCD Application"
        echo "  sync    - Force sync ArgoCD Application"
        echo "  monitor - Continuously monitor for changes"
        exit 1
        ;;
esac
