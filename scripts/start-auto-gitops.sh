#!/bin/bash

# Auto GitOps Monitor Startup Script
# This script starts the automated GitOps monitoring service

echo "🚀 Starting Auto GitOps Monitor..."

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed or not in PATH"
    echo "Please install Node.js and try again"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    echo "Please install kubectl and try again"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed or not in PATH"
    echo "Please install Helm and try again"
    exit 1
fi

# Check if Minikube is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster is not accessible"
    echo "Please ensure Minikube is running and try again"
    exit 1
fi

# Start the monitor
echo "✅ All prerequisites met, starting monitor..."
node /Users/sbd665/Mcp-server/mcp-deploy-repo/scripts/auto-gitops-monitor.js start
