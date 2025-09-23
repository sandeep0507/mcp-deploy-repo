#!/bin/bash

# GitHub Actions Setup Script
# This script helps set up the GitHub Actions workflow for ArgoCD deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Check if we're in a git repository
check_git_repo() {
    if [ ! -d ".git" ]; then
        error "Not in a git repository. Please run this script from the repository root."
        exit 1
    fi
    success "Git repository detected"
}

# Check if GitHub remote is configured
check_github_remote() {
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [[ "$remote_url" == *"github.com"* ]]; then
        success "GitHub remote detected: $remote_url"
        return 0
    else
        error "GitHub remote not found. Please add a GitHub remote:"
        echo "  git remote add origin https://github.com/username/repository.git"
        exit 1
    fi
}

# Generate kubeconfig for GitHub Actions
generate_kubeconfig() {
    log "Generating kubeconfig for GitHub Actions..."
    
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    # Export current kubeconfig
    kubectl config view --raw > kubeconfig.yaml
    
    # Base64 encode it
    if command -v base64 &> /dev/null; then
        base64 -i kubeconfig.yaml -o kubeconfig.b64
    else
        error "base64 command not found. Please install base64."
        exit 1
    fi
    
    success "Kubeconfig generated: kubeconfig.b64"
    log "Add this as KUBECONFIG secret in GitHub repository settings"
    
    # Show the content
    echo ""
    echo "=== KUBECONFIG Secret ==="
    cat kubeconfig.b64
    echo ""
    echo "=== End of KUBECONFIG Secret ==="
    echo ""
    
    # Clean up
    rm kubeconfig.yaml
}

# Check GitHub CLI
check_github_cli() {
    if command -v gh &> /dev/null; then
        success "GitHub CLI detected"
        return 0
    else
        warning "GitHub CLI not found. You can install it with:"
        echo "  brew install gh  # macOS"
        echo "  apt install gh   # Ubuntu"
        echo "  choco install gh # Windows"
        return 1
    fi
}

# Set up GitHub secrets
setup_github_secrets() {
    if ! check_github_cli; then
        warning "Skipping automatic secret setup. Please set up secrets manually:"
        echo "1. Go to your GitHub repository"
        echo "2. Click Settings > Secrets and variables > Actions"
        echo "3. Add the following secrets:"
        echo "   - KUBECONFIG: (content from kubeconfig.b64)"
        echo "   - ARGOCD_SERVER: (optional, your ArgoCD server URL)"
        echo "   - ARGOCD_TOKEN: (optional, your ArgoCD API token)"
        return 0
    fi
    
    log "Setting up GitHub secrets..."
    
    # Check if user is logged in
    if ! gh auth status &> /dev/null; then
        warning "Please log in to GitHub CLI first:"
        echo "  gh auth login"
        return 1
    fi
    
    # Read kubeconfig
    if [ -f "kubeconfig.b64" ]; then
        local kubeconfig_content=$(cat kubeconfig.b64)
        
        # Set KUBECONFIG secret
        echo "$kubeconfig_content" | gh secret set KUBECONFIG
        success "KUBECONFIG secret set"
    else
        warning "kubeconfig.b64 not found. Please run generate_kubeconfig first."
    fi
}

# Test GitHub Actions workflow
test_workflow() {
    log "Testing GitHub Actions workflow..."
    
    if ! check_github_cli; then
        warning "Cannot test workflow without GitHub CLI"
        return 1
    fi
    
    # Trigger test workflow
    gh workflow run "Test Deployment" --field test_type=all
    
    success "Test workflow triggered. Check the Actions tab for results."
}

# Show setup instructions
show_instructions() {
    echo ""
    echo "=== 🚀 GitHub Actions Setup Instructions ==="
    echo ""
    echo "1. Add GitHub Secrets:"
    echo "   - Go to your GitHub repository"
    echo "   - Click Settings > Secrets and variables > Actions"
    echo "   - Add KUBECONFIG secret with the content from kubeconfig.b64"
    echo ""
    echo "2. Optional ArgoCD Secrets:"
    echo "   - ARGOCD_SERVER: Your ArgoCD server URL"
    echo "   - ARGOCD_TOKEN: Your ArgoCD API token"
    echo ""
    echo "3. Test the Workflow:"
    echo "   - Go to Actions tab in your GitHub repository"
    echo "   - Run 'Test Deployment' workflow manually"
    echo "   - Or make a change to trigger 'ArgoCD Deploy' workflow"
    echo ""
    echo "4. Monitor Deployments:"
    echo "   - Check Actions tab for workflow runs"
    echo "   - Check your Kubernetes cluster for deployed applications"
    echo "   - Check ArgoCD UI for application status"
    echo ""
}

# Main function
main() {
    local action="${1:-setup}"
    
    case "$action" in
        "setup")
            log "Setting up GitHub Actions workflow..."
            check_git_repo
            check_github_remote
            generate_kubeconfig
            setup_github_secrets
            show_instructions
            ;;
        "test")
            test_workflow
            ;;
        "kubeconfig")
            generate_kubeconfig
            ;;
        "secrets")
            setup_github_secrets
            ;;
        "help")
            echo "Usage: $0 {setup|test|kubeconfig|secrets|help}"
            echo ""
            echo "Commands:"
            echo "  setup     - Complete setup (default)"
            echo "  test      - Test the workflow"
            echo "  kubeconfig - Generate kubeconfig only"
            echo "  secrets   - Set up GitHub secrets only"
            echo "  help      - Show this help"
            ;;
        *)
            error "Unknown action: $action"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
