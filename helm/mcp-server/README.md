# mcp-server Helm Chart

## Installing

```bash
helm upgrade --install mcp-server ./helm/mcp-server \
  --namespace mcp --create-namespace \
  --set image.repository=ghcr.io/OWNER/REPO \
  --set image.tag=latest \
  --set service.port=3000 \
  --set service.targetPort=3000
```

## Values
- image.repository: container image
- image.tag: image tag
- service.port: Service port
- service.targetPort: Container port
- env: list of environment variables
- container.command/args/workingDir: override container start
- ingress.enabled: enable ingress
