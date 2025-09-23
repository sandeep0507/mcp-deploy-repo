#!/bin/bash

# GitOps Sync Script
# This script monitors the Git repository and deploys changes to Minikube

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

# Function to sync from Git repository
sync_from_git() {
    print_status "Starting GitOps sync from remote repository..."
    
    # Pull latest changes
    print_status "Pulling latest changes from main branch..."
    git fetch origin
    git checkout main
    git pull origin main
    
    # Check if there are changes in helm/redis directory
    if git diff HEAD~1 HEAD --name-only | grep -q "helm/redis/"; then
        print_status "Changes detected in helm/redis directory"
        
        # Deploy using Helm
        print_status "Deploying Redis with updated configuration..."
        helm upgrade --install redis ./helm/redis \
            --namespace redis-prod \
            --set namespace=redis-prod \
            --wait --timeout=5m
            
        print_success "Redis deployment updated successfully!"
        
        # Verify deployment
        print_status "Verifying deployment..."
        kubectl get pods -n redis-prod
        kubectl get services -n redis-prod
        
        # Show resource limits
        print_status "Current resource limits:"
        kubectl get deployment redis -n redis-prod -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq .
        
    else
        print_status "No changes detected in helm/redis directory"
    fi
}

# Function to monitor for changes
monitor_changes() {
    print_status "Starting GitOps monitoring..."
    print_status "Monitoring repository for changes every 30 seconds..."
    
    while true; do
        # Check for new commits
        git fetch origin
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)
        
        if [ "$LOCAL" != "$REMOTE" ]; then
            print_status "New changes detected! Syncing..."
            sync_from_git
        else
            print_status "No new changes detected"
        fi
        
        sleep 30
    done
}

# Main execution
case "${1:-sync}" in
    "sync")
        sync_from_git
        ;;
    "monitor")
        monitor_changes
        ;;
    *)
        echo "Usage: $0 [sync|monitor]"
        echo "  sync    - Sync once from Git repository"
        echo "  monitor - Continuously monitor for changes"
        exit 1
        ;;
esac
