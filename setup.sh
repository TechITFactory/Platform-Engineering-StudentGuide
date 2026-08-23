#!/bin/bash
set -e

# Platform Engineering: No-Nonsense Edition - Environment Setup
# This script replaces Days 0-3 from the original course
# Installs: Docker, kind, kubectl, argocd CLI, crossplane CLI, helm

echo "========================================="
echo "Platform Engineering: No-Nonsense Setup"
echo "========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    MINGW*|MSYS*|CYGWIN*) MACHINE=Windows;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "Detected OS: ${MACHINE}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        exit 1
    fi
}

# 1. Check Docker
echo "Step 1: Checking Docker..."
if command_exists docker; then
    docker ps >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Docker is running"
    else
        echo -e "${YELLOW}⚠${NC}  Docker is installed but not running"
        echo "Please start Docker Desktop and run this script again"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} Docker not found"
    echo ""
    echo "Please install Docker:"
    echo "  - Mac: https://docs.docker.com/desktop/install/mac-install/"
    echo "  - Linux: https://docs.docker.com/engine/install/"
    echo "  - Windows: https://docs.docker.com/desktop/install/windows-install/"
    exit 1
fi
echo ""

# 2. Install kind
echo "Step 2: Installing kind (Kubernetes in Docker)..."
if command_exists kind; then
    echo -e "${GREEN}✓${NC} kind already installed ($(kind version))"
else
    case "${MACHINE}" in
        Mac)
            if command_exists brew; then
                brew install kind
                print_status "kind installed via Homebrew"
            else
                curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-darwin-amd64
                chmod +x ./kind
                sudo mv ./kind /usr/local/bin/kind
                print_status "kind installed"
            fi
            ;;
        Linux)
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
            print_status "kind installed"
            ;;
        Windows)
            echo -e "${YELLOW}⚠${NC}  Please install kind manually:"
            echo "  curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/latest/kind-windows-amd64"
            echo "  Move-Item .\\kind-windows-amd64.exe c:\\some-dir-in-your-PATH\\kind.exe"
            ;;
    esac
fi
echo ""

# 3. Install kubectl
echo "Step 3: Installing kubectl..."
if command_exists kubectl; then
    echo -e "${GREEN}✓${NC} kubectl already installed ($(kubectl version --client --short 2>/dev/null || kubectl version --client))"
else
    case "${MACHINE}" in
        Mac)
            if command_exists brew; then
                brew install kubectl
                print_status "kubectl installed via Homebrew"
            else
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
                chmod +x kubectl
                sudo mv kubectl /usr/local/bin/
                print_status "kubectl installed"
            fi
            ;;
        Linux)
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
            print_status "kubectl installed"
            ;;
        Windows)
            echo -e "${YELLOW}⚠${NC}  Please install kubectl manually:"
            echo "  curl.exe -LO \"https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe\""
            ;;
    esac
fi
echo ""

# 4. Install Helm
echo "Step 4: Installing Helm..."
if command_exists helm; then
    echo -e "${GREEN}✓${NC} Helm already installed ($(helm version --short))"
else
    case "${MACHINE}" in
        Mac)
            if command_exists brew; then
                brew install helm
                print_status "Helm installed via Homebrew"
            else
                curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                print_status "Helm installed"
            fi
            ;;
        Linux)
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            print_status "Helm installed"
            ;;
        Windows)
            echo -e "${YELLOW}⚠${NC}  Please install Helm manually via Chocolatey:"
            echo "  choco install kubernetes-helm"
            ;;
    esac
fi
echo ""

# 5. Install ArgoCD CLI
echo "Step 5: Installing ArgoCD CLI..."
if command_exists argocd; then
    echo -e "${GREEN}✓${NC} ArgoCD CLI already installed ($(argocd version --client --short 2>/dev/null || echo 'installed'))"
else
    case "${MACHINE}" in
        Mac)
            if command_exists brew; then
                brew install argocd
                print_status "ArgoCD CLI installed via Homebrew"
            else
                curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-amd64
                chmod +x argocd
                sudo mv argocd /usr/local/bin/
                print_status "ArgoCD CLI installed"
            fi
            ;;
        Linux)
            curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
            chmod +x argocd
            sudo mv argocd /usr/local/bin/
            print_status "ArgoCD CLI installed"
            ;;
        Windows)
            echo -e "${YELLOW}⚠${NC}  Please install ArgoCD CLI manually:"
            echo "  Download from: https://github.com/argoproj/argo-cd/releases/latest"
            ;;
    esac
fi
echo ""

# 6. Install Crossplane CLI
echo "Step 6: Installing Crossplane CLI..."
if command_exists crossplane; then
    echo -e "${GREEN}✓${NC} Crossplane CLI already installed"
else
    case "${MACHINE}" in
        Mac|Linux)
            curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
            sudo mv crossplane /usr/local/bin/
            print_status "Crossplane CLI installed"
            ;;
        Windows)
            echo -e "${YELLOW}⚠${NC}  Please install Crossplane CLI manually:"
            echo "  Download from: https://github.com/crossplane/crossplane/releases"
            ;;
    esac
fi
echo ""

# 7. Create kind cluster
echo "Step 7: Creating kind cluster..."
if kind get clusters 2>/dev/null | grep -q "^platform-engineering$"; then
    echo -e "${YELLOW}⚠${NC}  Cluster 'platform-engineering' already exists"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kind delete cluster --name platform-engineering
        echo "Creating new cluster..."
    else
        echo "Using existing cluster"
        echo ""
        echo "========================================="
        echo "Setup Complete!"
        echo "========================================="
        exit 0
    fi
fi

cat <<EOF | kind create cluster --name platform-engineering --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.31.0
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30443
    hostPort: 30443
    protocol: TCP
EOF

print_status "kind cluster created"
echo ""

# 8. Verify cluster
echo "Step 8: Verifying cluster..."
sleep 5
kubectl cluster-info --context kind-platform-engineering
print_status "Cluster is ready"
echo ""

# 9. Create namespaces
echo "Step 9: Creating namespaces..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace backstage --dry-run=client -o yaml | kubectl apply -f -
print_status "Namespaces created"
echo ""

# Summary
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Installed:"
echo "  ✓ Docker (verified running)"
echo "  ✓ kind (Kubernetes in Docker)"
echo "  ✓ kubectl (Kubernetes CLI)"
echo "  ✓ Helm (Package manager)"
echo "  ✓ ArgoCD CLI"
echo "  ✓ Crossplane CLI"
echo ""
echo "Created:"
echo "  ✓ kind cluster: platform-engineering"
echo "  ✓ Namespaces: argocd, crossplane-system, backstage"
echo ""
echo "Next Steps:"
echo "  1. Verify cluster: kubectl get nodes"
echo "  2. Start with Bite 01: cd 01-kubernetes-essentials"
echo "  3. Open README.md and follow the bites"
echo ""
echo "Happy Learning! 🚀"
