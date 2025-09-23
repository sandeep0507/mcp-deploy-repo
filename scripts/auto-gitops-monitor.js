#!/usr/bin/env node

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class AutoGitOpsMonitor {
    constructor() {
        this.repoPath = '/Users/sbd665/Mcp-server/mcp-deploy-repo';
        this.remoteUrl = 'https://github.com/SKSTAE/mcp-deploy-repo.git';
        this.checkInterval = 3 * 60 * 1000; // 3 minutes in milliseconds
        this.lastCommitHash = null;
        this.isRunning = false;
        this.logFile = path.join(this.repoPath, 'gitops-monitor.log');
    }

    log(message) {
        const timestamp = new Date().toISOString();
        const logMessage = `[${timestamp}] ${message}`;
        console.log(logMessage);
        
        // Write to log file
        fs.appendFileSync(this.logFile, logMessage + '\n');
    }

    async checkForChanges() {
        try {
            this.log('🔍 Checking for changes in remote repository...');
            
            // Fetch latest changes from remote
            execSync('git fetch origin', { cwd: this.repoPath, stdio: 'pipe' });
            
            // Get the latest commit hash from remote
            const remoteCommitHash = execSync('git rev-parse origin/main', { 
                cwd: this.repoPath, 
                encoding: 'utf8' 
            }).trim();
            
            // Get current local commit hash
            const localCommitHash = execSync('git rev-parse HEAD', { 
                cwd: this.repoPath, 
                encoding: 'utf8' 
            }).trim();
            
            this.log(`📊 Remote commit: ${remoteCommitHash.substring(0, 8)}`);
            this.log(`📊 Local commit: ${localCommitHash.substring(0, 8)}`);
            
            // Check if there are new changes
            if (remoteCommitHash !== localCommitHash) {
                this.log('🆕 New changes detected! Starting automated deployment...');
                await this.deployChanges(remoteCommitHash);
            } else {
                this.log('✅ No new changes detected');
            }
            
        } catch (error) {
            this.log(`❌ Error checking for changes: ${error.message}`);
        }
    }

    async deployChanges(commitHash) {
        try {
            this.log('🔄 Pulling latest changes...');
            execSync('git pull origin main', { cwd: this.repoPath, stdio: 'pipe' });
            
            this.log('🚀 Deploying changes via GitOps...');
            
            // Check what changed
            const changedFiles = execSync('git diff --name-only HEAD~1 HEAD', { 
                cwd: this.repoPath, 
                encoding: 'utf8' 
            }).trim().split('\n').filter(f => f);
            
            this.log(`📝 Changed files: ${changedFiles.join(', ')}`);
            
            // Deploy based on what changed
            if (changedFiles.some(f => f.includes('helm/redis'))) {
                this.log('🔴 Redis configuration changed - deploying Redis...');
                await this.deployRedis();
            }
            
            if (changedFiles.some(f => f.includes('helm/mcp-server'))) {
                this.log('🔵 MCP Server configuration changed - deploying MCP Server...');
                await this.deployMcpServer();
            }
            
            this.log('✅ Automated deployment completed successfully!');
            
        } catch (error) {
            this.log(`❌ Error during deployment: ${error.message}`);
        }
    }

    async deployRedis() {
        try {
            this.log('🔴 Deploying Redis with Helm...');
            
            // Deploy Redis using Helm
            const helmCommand = `helm upgrade --install redis ./helm/redis --namespace redis-prod --create-namespace --set namespace=redis-prod`;
            execSync(helmCommand, { cwd: this.repoPath, stdio: 'pipe' });
            
            // Wait for deployment to be ready
            this.log('⏳ Waiting for Redis deployment to be ready...');
            execSync('kubectl rollout status deployment/redis -n redis-prod --timeout=300s', { stdio: 'pipe' });
            
            // Get pod status
            const podStatus = execSync('kubectl get pods -n redis-prod -l app.kubernetes.io/name=redis', { 
                encoding: 'utf8' 
            });
            
            this.log('🔴 Redis deployment status:');
            this.log(podStatus);
            
        } catch (error) {
            this.log(`❌ Error deploying Redis: ${error.message}`);
        }
    }

    async deployMcpServer() {
        try {
            this.log('🔵 Deploying MCP Server with Helm...');
            
            // Deploy MCP Server using Helm
            const helmCommand = `helm upgrade --install mcp-server ./helm/mcp-server --namespace mcp-server --create-namespace --set namespace=mcp-server`;
            execSync(helmCommand, { cwd: this.repoPath, stdio: 'pipe' });
            
            // Wait for deployment to be ready
            this.log('⏳ Waiting for MCP Server deployment to be ready...');
            execSync('kubectl rollout status deployment/mcp-server -n mcp-server --timeout=300s', { stdio: 'pipe' });
            
            // Get pod status
            const podStatus = execSync('kubectl get pods -n mcp-server -l app.kubernetes.io/name=mcp-server', { 
                encoding: 'utf8' 
            });
            
            this.log('🔵 MCP Server deployment status:');
            this.log(podStatus);
            
        } catch (error) {
            this.log(`❌ Error deploying MCP Server: ${error.message}`);
        }
    }

    start() {
        if (this.isRunning) {
            this.log('⚠️ Monitor is already running');
            return;
        }

        this.log('🚀 Starting Auto GitOps Monitor...');
        this.log(`⏰ Check interval: ${this.checkInterval / 1000} seconds`);
        this.log(`📁 Repository: ${this.repoPath}`);
        this.log(`🌐 Remote: ${this.remoteUrl}`);
        
        this.isRunning = true;
        
        // Initial check
        this.checkForChanges();
        
        // Set up interval
        this.interval = setInterval(() => {
            this.checkForChanges();
        }, this.checkInterval);
        
        this.log('✅ Auto GitOps Monitor started successfully!');
    }

    stop() {
        if (!this.isRunning) {
            this.log('⚠️ Monitor is not running');
            return;
        }

        this.log('🛑 Stopping Auto GitOps Monitor...');
        this.isRunning = false;
        
        if (this.interval) {
            clearInterval(this.interval);
        }
        
        this.log('✅ Auto GitOps Monitor stopped');
    }

    status() {
        this.log(`📊 Monitor Status: ${this.isRunning ? 'Running' : 'Stopped'}`);
        this.log(`⏰ Check Interval: ${this.checkInterval / 1000} seconds`);
        this.log(`📁 Repository: ${this.repoPath}`);
        this.log(`🌐 Remote: ${this.remoteUrl}`);
        
        if (this.lastCommitHash) {
            this.log(`📝 Last Checked Commit: ${this.lastCommitHash.substring(0, 8)}`);
        }
    }
}

// CLI interface
const monitor = new AutoGitOpsMonitor();

const command = process.argv[2];

switch (command) {
    case 'start':
        monitor.start();
        break;
    case 'stop':
        monitor.stop();
        break;
    case 'status':
        monitor.status();
        break;
    case 'check':
        monitor.checkForChanges();
        break;
    default:
        console.log('Usage: node auto-gitops-monitor.js [start|stop|status|check]');
        console.log('');
        console.log('Commands:');
        console.log('  start   - Start the automated GitOps monitor');
        console.log('  stop    - Stop the automated GitOps monitor');
        console.log('  status  - Show monitor status');
        console.log('  check   - Manually check for changes once');
        process.exit(1);
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Received SIGINT, shutting down gracefully...');
    monitor.stop();
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
    monitor.stop();
    process.exit(0);
});
