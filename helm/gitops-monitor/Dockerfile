FROM node:18-alpine

# Install required system packages
RUN apk add --no-cache git curl

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy the monitor script
COPY monitor.js ./

# Create logs directory
RUN mkdir -p /app/logs

# Expose port
EXPOSE 3000

# Start the monitor
CMD ["node", "monitor.js", "start"]
