#!/bin/bash
set -e

# Install Ingress Controller for kind cluster
# This script installs NGINX Ingress Controller configured for kind

echo "========================================="
echo "Installing NGINX Ingress Controller"
echo "========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        exit 1
    fi
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗${NC} kubectl not found. Please run setup.sh first."
    exit 1
fi

# Check if cluster exists
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗${NC} Kubernetes cluster not found. Please run setup.sh first."
    exit 1
fi

echo "Step 1: Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
print_status "Ingress controller manifest applied"
echo ""

echo "Step 2: Waiting for ingress controller to be ready..."
echo "This may take a minute or two..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
print_status "Ingress controller is ready"
echo ""

echo "Step 3: Verifying ingress controller..."
kubectl get pods -n ingress-nginx
echo ""

echo "Step 4: Checking ingress class..."
kubectl get ingressclass
echo ""

# Test ingress connectivity
echo "Step 5: Testing ingress connectivity..."
echo "Deploying test application..."

# Create test namespace
kubectl create namespace ingress-test --dry-run=client -o yaml | kubectl apply -f -

# Deploy test app
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  namespace: ingress-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
  namespace: ingress-test
spec:
  selector:
    app: hello
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-ingress
  namespace: ingress-test
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: hello.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-service
            port:
              number: 80
EOF

print_status "Test application deployed"
echo ""

echo "Step 6: Waiting for test deployment..."
kubectl wait --namespace ingress-test \
  --for=condition=available deployment/hello-app \
  --timeout=120s
print_status "Test application is ready"
echo ""

# Get ingress status
echo "Step 7: Checking ingress status..."
kubectl get ingress -n ingress-test
echo ""

echo "========================================="
echo "Ingress Controller Installation Complete!"
echo "========================================="
echo ""
echo "✓ NGINX Ingress Controller installed"
echo "✓ Ingress class 'nginx' configured"
echo "✓ Test application deployed"
echo ""
echo "Testing Ingress:"
echo "  1. Add to /etc/hosts (or C:\\Windows\\System32\\drivers\\etc\\hosts on Windows):"
echo "     127.0.0.1 hello.local"
echo ""
echo "  2. Test with curl:"
echo "     curl http://hello.local"
echo ""
echo "  3. Or open in browser:"
echo "     http://hello.local"
echo ""
echo "  4. You should see: 'Hello, world!'"
echo ""
echo "Cleanup test application:"
echo "  kubectl delete namespace ingress-test"
echo ""
echo "For WSL2 users:"
echo "  - Edit /etc/hosts in WSL: sudo nano /etc/hosts"
echo "  - Edit hosts in Windows: C:\\Windows\\System32\\drivers\\etc\\hosts"
echo "  - Use 127.0.0.1 (localhost) for both"
echo ""
echo "Happy testing! 🚀"
