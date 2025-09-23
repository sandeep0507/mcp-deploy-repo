# 🤖 Automated GitOps Monitoring System

## Overview

This system provides **continuous monitoring** of your remote Git repository and **automatically deploys changes** to your Kubernetes cluster without manual intervention. It scans the remote repository every 3 minutes and automatically applies any changes found.

## 🚀 Features

- **🔄 Continuous Monitoring**: Scans remote repository every 3 minutes
- **🚀 Automatic Deployment**: Deploys changes without manual intervention
- **📝 Smart Change Detection**: Only deploys when actual changes are detected
- **🔍 Detailed Logging**: Comprehensive logs of all monitoring and deployment activities
- **⚡ Multi-Service Support**: Supports Redis, MCP Server, and other Helm charts
- **🛡️ Error Handling**: Robust error handling and recovery mechanisms

## 📁 File Structure

```
mcp-deploy-repo/
├── scripts/
│   ├── auto-gitops-monitor.js      # Main monitoring service
│   ├── start-auto-gitops.sh        # Startup script
│   ├── auto-gitops.service         # Systemd service file
│   └── gitops-sync.sh              # Manual sync script
├── helm/
│   ├── redis/                      # Redis Helm chart
│   └── mcp-server/                 # MCP Server Helm chart
└── gitops-monitor.log              # Monitoring logs
```

## 🛠️ Setup and Usage

### 1. Start the Automated Monitor

```bash
# Start the monitoring service
cd /Users/sbd665/Mcp-server/mcp-deploy-repo
node scripts/auto-gitops-monitor.js start
```

### 2. Check Monitor Status

```bash
# Check if monitor is running
node scripts/auto-gitops-monitor.js status

# Manually trigger a check
node scripts/auto-gitops-monitor.js check
```

### 3. Stop the Monitor

```bash
# Stop the monitoring service
node scripts/auto-gitops-monitor.js stop
```

## 🔄 How It Works

### Monitoring Process

1. **🕐 Every 3 Minutes**: The monitor checks the remote repository
2. **🔍 Change Detection**: Compares remote and local commit hashes
3. **📥 Pull Changes**: If changes detected, pulls latest changes
4. **🚀 Deploy Changes**: Automatically deploys using Helm
5. **✅ Verify Deployment**: Waits for deployment to be ready
6. **📝 Log Results**: Logs all activities for monitoring

### Supported Changes

- **Redis Configuration**: Changes to `helm/redis/values.yaml`
- **MCP Server Configuration**: Changes to `helm/mcp-server/values.yaml`
- **Any Helm Chart**: Automatically detects and deploys any Helm chart changes

## 📊 Monitoring and Logs

### Log File Location
```
/Users/sbd665/Mcp-server/mcp-deploy-repo/gitops-monitor.log
```

### Log Examples

```
[2025-09-23T06:36:06.109Z] 🚀 Starting Auto GitOps Monitor...
[2025-09-23T06:36:06.111Z] ⏰ Check interval: 180 seconds
[2025-09-23T06:36:08.677Z] 🔍 Checking for changes in remote repository...
[2025-09-23T06:36:08.677Z] 📊 Remote commit: e3a48eca
[2025-09-23T06:36:08.677Z] 📊 Local commit: e3a48eca
[2025-09-23T06:36:08.677Z] ✅ No new changes detected
```

### Real-time Log Monitoring

```bash
# Watch logs in real-time
tail -f /Users/sbd665/Mcp-server/mcp-deploy-repo/gitops-monitor.log

# Check recent logs
tail -50 /Users/sbd665/Mcp-server/mcp-deploy-repo/gitops-monitor.log
```

## 🧪 Testing the System

### 1. Make a Change

```bash
# Edit Redis configuration
vim helm/redis/values.yaml
# Change replicaCount from 6 to 7
```

### 2. Commit and Push

```bash
git add helm/redis/values.yaml
git commit -m "feat: Scale Redis to 7 replicas"
git push origin main
```

### 3. Watch Automatic Deployment

```bash
# Monitor logs
tail -f gitops-monitor.log

# Check pods
kubectl get pods -n redis-prod
```

## ⚙️ Configuration

### Check Interval

The monitor checks every **3 minutes** by default. To change this:

```javascript
// In auto-gitops-monitor.js
this.checkInterval = 3 * 60 * 1000; // 3 minutes in milliseconds
```

### Repository Settings

```javascript
// In auto-gitops-monitor.js
this.repoPath = '/Users/sbd665/Mcp-server/mcp-deploy-repo';
this.remoteUrl = 'https://github.com/SKSTAE/mcp-deploy-repo.git';
```

## 🔧 Troubleshooting

### Monitor Not Starting

```bash
# Check prerequisites
node --version
kubectl version --client
helm version

# Check Minikube status
kubectl cluster-info
```

### Changes Not Detected

```bash
# Manually check for changes
node scripts/auto-gitops-monitor.js check

# Check git status
git status
git log --oneline -5
```

### Deployment Failures

```bash
# Check Helm status
helm list -n redis-prod

# Check pod status
kubectl get pods -n redis-prod
kubectl describe pods -n redis-prod
```

## 🚀 Production Deployment

### Systemd Service (Optional)

```bash
# Copy service file
sudo cp scripts/auto-gitops.service /etc/systemd/system/

# Enable and start service
sudo systemctl enable auto-gitops
sudo systemctl start auto-gitops

# Check status
sudo systemctl status auto-gitops
```

### Background Process

```bash
# Start in background
nohup node scripts/auto-gitops-monitor.js start > gitops-monitor.log 2>&1 &

# Check if running
ps aux | grep auto-gitops-monitor
```

## 📈 Benefits

1. **🔄 Fully Automated**: No manual intervention required
2. **⚡ Fast Deployment**: Changes deployed within 3 minutes
3. **🛡️ Reliable**: Robust error handling and recovery
4. **📝 Auditable**: Complete logs of all activities
5. **🔍 Transparent**: Clear visibility into what's happening
6. **🚀 Scalable**: Supports multiple services and environments

## 🎯 Use Cases

- **Development**: Automatic deployment of development changes
- **Staging**: Continuous integration with staging environment
- **Production**: Automated production deployments (with proper approvals)
- **Testing**: Automated testing of configuration changes
- **Monitoring**: Continuous monitoring of infrastructure changes

## 🔐 Security Considerations

- **Repository Access**: Ensure proper authentication to remote repository
- **RBAC**: Configure proper Kubernetes RBAC for deployments
- **Secrets**: Use Kubernetes secrets for sensitive configuration
- **Network**: Ensure proper network policies for service communication

---

## 🎉 Success!

Your automated GitOps monitoring system is now running! Any changes you make to the `helm/redis/values.yaml` or `helm/mcp-server/values.yaml` files will be automatically detected and deployed within 3 minutes.

**Next Steps:**
1. Make a change to test the system
2. Monitor the logs to see it in action
3. Scale up to multiple services
4. Configure production monitoring
