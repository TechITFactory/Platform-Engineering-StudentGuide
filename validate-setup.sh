#!/bin/bash
echo "=== Toolchain Validation ==="
docker version --format 'Docker: {{.Server.Version}}' || echo "Docker not running!"
kubectl version --client -o yaml | grep gitVersion || echo "kubectl missing!"
kind version || echo "kind missing!"
helm version --template 'Helm: {{.Version}}' || echo "helm missing!"
echo -e "\nNode.js: $(node --version)"
echo "npm: $(npm --version)"
git --version
