#!/bin/bash

# =============================================================================
# Day 03 - Repository & Branching Strategy Setup Script
# =============================================================================
# This script automates all steps from Day 03 to set up GitOps repository
# structure, CODEOWNERS, documentation, and branching strategy.
#
# Usage: bash setup-day-03.sh
#
# What This Script Creates:
# -------------------------
# • platform-gitops-repo/ - Main GitOps repository with Git initialization
# • apps/{dev,staging,prod}/ - Environment-specific application directories
# • infrastructure/{argocd,crossplane,backstage}/ - Platform infrastructure folders
# • .gitignore - Prevents committing secrets, IDE files, and build artifacts
# • .github/CODEOWNERS - Automatic PR review assignment by team/path
# • .github/COMMIT_CONVENTION.md - Conventional commit message guide
# • .github/PULL_REQUEST_TEMPLATE.md - PR checklist and template
# • .github/workflows/ci.yml - GitHub Actions pipeline (lint, validate, security scan)
# • .yamllint.yml - YAML linting configuration
# • .commitlintrc.json - Commit message validation rules
# • README.md - Comprehensive repository documentation with quick start
# • artifacts/section-00/repo-strategy.md - Multi-repo topology and branching model
# • artifacts/section-00/github-protection.md - Branch protection rules guide
# • artifacts/section-00/setup-summary.md - Setup verification checklist
# • All commits following conventional commit format
# =============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

print_error() {
    echo -e "${RED}✗${NC} ${1}"
}

# =============================================================================
# Step 1: Initialize GitOps Repository
# =============================================================================
initialize_gitops_repo() {
    print_step "Step 1: Initializing GitOps Repository"

    # Create platform GitOps repository
    mkdir -p platform-gitops-repo
    cd platform-gitops-repo

    # Initialize git if not already initialized
    if [ ! -d .git ]; then
        git init
        git checkout -b main
        print_success "Git repository initialized"
    else
        print_warning "Git repository already exists, skipping initialization"
    fi

    # Create .gitignore
    cat > .gitignore << 'EOF'
# Kubernetes/IDE
.idea/
.vscode/
*.swp
.DS_Store

# Secrets (CRITICAL!)
*.pem
*.key
.env
secrets.yaml
*-secret.yaml

# Build artifacts
*.log
dist/
build/

# OS files
Thumbs.db
EOF

    print_success "Created .gitignore"

    # Create folder structure
    mkdir -p apps/{dev,staging,prod}
    mkdir -p infrastructure/{argocd,crossplane,backstage}

    print_success "Created folder structure"

    # Create placeholder READMEs
    cat > apps/README.md << 'EOF'
# Applications Directory

This directory contains application manifests organized by environment:

- `dev/` - Development environment applications
- `staging/` - Staging environment applications
- `prod/` - Production environment applications

Each subdirectory should contain Kubernetes manifests and ArgoCD Application definitions.
EOF

    cat > infrastructure/README.md << 'EOF'
# Infrastructure Directory

This directory contains platform infrastructure components:

- `argocd/` - ArgoCD bootstrap and configuration
- `crossplane/` - Crossplane compositions and providers
- `backstage/` - Backstage portal deployment
EOF

    print_success "Created README files"

    # Initial commit
    git add .
    git commit -m "chore: initialize platform gitops repository" || print_warning "Nothing to commit or already committed"

    print_success "Step 1 completed: GitOps repository initialized"
    echo ""
}

# =============================================================================
# Step 2: Setup CODEOWNERS
# =============================================================================
setup_codeowners() {
    print_step "Step 2: Setting up CODEOWNERS"

    # Create .github directory
    mkdir -p .github

    # Create CODEOWNERS file
    cat > .github/CODEOWNERS << 'EOF'
# CODEOWNERS - Automatic PR Review Assignment
# ===========================================
# Each line is a file pattern followed by one or more owners.
# Owners will be requested for review when someone opens a PR that modifies files matching that pattern.

# Platform team owns core infrastructure
/infrastructure/ @platform-engineering-team

# Infrastructure team owns database compositions
/infrastructure/crossplane/ @infrastructure-team

# ArgoCD owned by platform team
/infrastructure/argocd/ @platform-engineering-team

# Backstage owned by platform team
/infrastructure/backstage/ @platform-engineering-team

# App teams own their namespaces
/apps/team-alpha/ @team-alpha
/apps/team-beta/ @team-beta

# Production environment requires additional review
/apps/prod/ @platform-engineering-team @security-team

# Root level configuration requires platform team review
/*.yaml @platform-engineering-team
/*.json @platform-engineering-team
/.github/ @platform-engineering-team
EOF

    git add .github/CODEOWNERS
    git commit -m "chore: add CODEOWNERS for PR routing" || print_warning "Nothing to commit or already committed"

    print_success "Step 2 completed: CODEOWNERS configured"
    echo ""
}

# =============================================================================
# Step 3: Create Commit Convention Guide
# =============================================================================
create_commit_guide() {
    print_step "Step 3: Creating commit convention guide"

    cat > .github/COMMIT_CONVENTION.md << 'EOF'
# Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

## Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools and libraries

## Scopes

- `argocd`: ArgoCD related changes
- `crossplane`: Crossplane related changes
- `backstage`: Backstage related changes
- `k8s`: Kubernetes manifests
- `ci`: CI/CD pipeline changes
- `deps`: Dependency updates

## Examples

### Good Commits
```
feat(argocd): add applicationset for multi-env deployment
fix(backstage): correct template parameter validation
docs(readme): update branching strategy documentation
chore(deps): upgrade crossplane to v1.14.0
refactor(k8s): simplify ingress configuration
```

### Bad Commits (Don't do this!)
```
updated stuff
fix bug
wip
asdf
.
```

## Breaking Changes

Breaking changes should be indicated in the commit message:

```
feat(api)!: remove deprecated endpoint

BREAKING CHANGE: The /v1/old endpoint has been removed. Use /v2/new instead.
```
EOF

    git add .github/COMMIT_CONVENTION.md
    git commit -m "docs: add commit convention guide" || print_warning "Nothing to commit or already committed"

    print_success "Step 3 completed: Commit convention guide created"
    echo ""
}

# =============================================================================
# Step 4: Create GitHub Protection Rules Documentation
# =============================================================================
create_protection_rules_doc() {
    print_step "Step 4: Creating GitHub protection rules documentation"

    mkdir -p artifacts/section-00

    cat > artifacts/section-00/github-protection.md << 'EOF'
# GitHub Branch Protection Rules

These rules should be configured in GitHub Settings > Branches > Branch protection rules for the `main` branch.

## Required Status Checks

### Pull Request Reviews
- [x] Require pull request reviews before merging
  - Required approving reviews: **1**
  - Dismiss stale pull request approvals when new commits are pushed: **Enabled**
  - Require review from Code Owners: **Enabled**
  - Restrict who can dismiss pull request reviews: **Enabled**

### Status Checks
- [x] Require status checks to pass before merging
- [x] Require branches to be up to date before merging

**Required Status Checks:**
1. `ci/lint` - ESLint, Prettier, YAML lint
2. `ci/test` - Unit and integration tests
3. `ci/security` - Trivy vulnerability scanning
4. `ci/coverage` - Code coverage (minimum 80%)
5. `ci/commit-lint` - Conventional commit validation

### Additional Protections
- [x] Require linear history (no merge commits)
  - Use **squash merging** or **rebase merging**
- [x] Block force pushes
- [x] Block branch deletion
- [x] Require signed commits (optional, but recommended)

## CODEOWNERS Enforcement
- [x] Require review from code owners
- [x] Dismiss stale reviews on new commits

## CI Pipeline Checks

### Linting
- **ESLint**: JavaScript/TypeScript code quality
- **Prettier**: Code formatting
- **YAML Lint**: Kubernetes manifest validation
- **Markdown Lint**: Documentation quality

### Testing
- **Unit Tests**: Jest, Pytest
- **Integration Tests**: End-to-end testing
- **Coverage**: SonarQube (minimum 80%)

### Security
- **Trivy**: Container image scanning
- **Checkov**: Infrastructure as Code scanning
- **Secret Scanning**: Detect committed secrets
- **Dependency Scanning**: Known vulnerabilities in dependencies

### Additional Checks
- **Conventional Commits**: Enforce commit message format
- **PR Size**: Warn on large PRs (>500 lines changed)
- **Breaking Changes**: Require additional approval for breaking changes

## Setup Instructions

### GitHub CLI
```bash
# Install GitHub CLI if not already installed
# https://cli.github.com/

# Authenticate
gh auth login

# Enable branch protection
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --input protection-rules.json
```

### protection-rules.json
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "ci/lint",
      "ci/test",
      "ci/security",
      "ci/coverage",
      "ci/commit-lint"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismissal_restrictions": {},
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

## Bypass Options (Use Sparingly!)

Emergency hotfixes may require bypass (e.g., critical production incident):
- Create an incident ticket
- Get approval from platform lead
- Use emergency access (logged and audited)
- Create follow-up PR with full review

## Monitoring

Track bypass events and failed CI checks:
- GitHub audit log
- CI/CD metrics dashboard
- Security scanning reports
EOF

    git add artifacts/section-00/github-protection.md
    git commit -m "docs: add GitHub branch protection rules" || print_warning "Nothing to commit or already committed"

    print_success "Step 4 completed: Protection rules documented"
    echo ""
}

# =============================================================================
# Step 5: Create Repository Strategy Document
# =============================================================================
create_repo_strategy_doc() {
    print_step "Step 5: Creating repository strategy document"

    cat > artifacts/section-00/repo-strategy.md << 'EOF'
# Repository & Branching Strategy

## Repository Topology (Multi-repo Approach)

### Platform Repositories

#### 1. platform-core (Backstage Portal)
- **Owner**: Platform Engineering team
- **Purpose**: Developer portal and self-service platform
- **Contains**:
  - Backstage frontend and backend
  - Software templates
  - Custom plugins
  - Portal configuration

#### 2. platform-gitops (ArgoCD Source of Truth)
- **Owner**: Platform Engineering team
- **Purpose**: GitOps source of truth for all deployments
- **Contains**:
  - Application manifests (dev/staging/prod)
  - ArgoCD Application definitions
  - Infrastructure bootstrap apps
  - Environment-specific configurations

#### 3. platform-infra (Crossplane Compositions)
- **Owner**: Infrastructure team
- **Purpose**: Cloud infrastructure as code
- **Contains**:
  - Crossplane XRDs (API definitions)
  - Compositions (implementation)
  - Provider configurations
  - Composite resources

### Application Repositories

#### 4. app-* (Team-Owned Services)
- **Owner**: Application teams
- **Purpose**: Individual microservices
- **Generated**: Via Backstage software templates
- **Contains**:
  - Application source code
  - Kubernetes manifests (k8s/ directory)
  - CI/CD pipeline configuration
  - .backstage.yaml catalog definition

## Branching Model (Trunk-Based Development)

### Main Branch
- **Always deployable**: Every commit to main is production-ready
- **Protected**: No direct pushes allowed
- **Auto-deploys**: To dev and staging environments
- **Source of truth**: Single branch to track

### Feature Branches
- **Short-lived**: Maximum 48 hours
- **Naming convention**:
  - `feat/*` - New features
  - `fix/*` - Bug fixes
  - `chore/*` - Maintenance tasks
  - `docs/*` - Documentation updates
  - `refactor/*` - Code refactoring
  - `test/*` - Test additions/updates

### No Long-Lived Branches
- No `develop` branch
- No `release` branches
- No `hotfix` branches (use feature branches + fast-track PR)

## Pull Request Governance

### Mandatory Requirements
1. **Code Review**: Minimum 1 approval from CODEOWNERS
2. **CI Checks**: All checks must pass
3. **Conventional Commits**: Enforced via pre-commit hook
4. **Linear History**: Squash or rebase merge only
5. **Branch Up-to-Date**: Must rebase on latest main

### Review Guidelines
- **Response Time**: Within 4 business hours
- **Review Scope**: Logic, security, performance, maintainability
- **Nitpicks**: Mark as non-blocking
- **Approval**: Use GitHub "Approve" button explicitly

### PR Size Guidelines
- **Small**: <100 lines changed (ideal)
- **Medium**: 100-500 lines changed (acceptable)
- **Large**: >500 lines changed (split into smaller PRs)

## Environment Promotion Flow

```
┌─────────────┐
│  Developer  │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  Feature Branch     │
│  feat/add-template  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Pull Request       │
│  + CI Checks        │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Main Branch        │
│  (after merge)      │
└──────┬──────────────┘
       │
       ├─────────────────────┐
       │                     │
       ▼                     ▼
┌─────────────┐      ┌──────────────┐
│ Dev Cluster │      │ Staging      │
│ (auto)      │      │ Cluster      │
└─────────────┘      │ (auto)       │
                     └──────┬───────┘
                            │
                            │ (manual)
                            ▼
                     ┌──────────────┐
                     │  Git Tag     │
                     │  v1.2.0      │
                     └──────┬───────┘
                            │
                            ▼
                     ┌──────────────┐
                     │ Prod Cluster │
                     └──────────────┘
```

### Environments

#### Dev Environment
- **Trigger**: Every commit to main
- **Purpose**: Rapid feedback, testing
- **Approvals**: None required
- **Rollback**: Automatic on failure

#### Staging Environment
- **Trigger**: Merge to main
- **Purpose**: Pre-production validation
- **Approvals**: None required (same as prod config)
- **Rollback**: Manual if needed

#### Production Environment
- **Trigger**: Git tag (v1.2.0 format)
- **Purpose**: Live user traffic
- **Approvals**: Manual tag creation only
- **Rollback**: Revert tag or create new tag

### Why Manual Production Promotion?

1. **Human Checkpoint**: Final verification before production
2. **Controlled Release**: Define release windows
3. **Easy Rollback**: Revert tag, not code
4. **Compliance**: Audit trail for production changes
5. **Coordination**: Align with maintenance windows

## Security & Compliance

### Secret Management
- ❌ **NEVER** commit secrets to Git
- ✅ Use Sealed Secrets (Bitnami)
- ✅ Use External Secrets Operator (ESO)
- ✅ Reference secrets from HashiCorp Vault

### Audit Trail
- Every change via Git (reviewable history)
- Commit messages link to tickets
- PR reviews provide justification
- Deployment events tracked in ArgoCD

### RBAC Alignment
- GitHub teams match Kubernetes RBAC groups
- CODEOWNERS enforce separation of duties
- Branch protection prevents unauthorized changes

## Best Practices

### Do's ✅
- Keep feature branches short-lived
- Write descriptive commit messages
- Request reviews promptly
- Rebase before merging
- Tag releases semantically (v1.2.0)
- Document breaking changes

### Don'ts ❌
- Don't force push to main
- Don't merge without approval
- Don't bypass CI checks
- Don't commit secrets
- Don't create long-lived branches
- Don't use `git merge` (use rebase/squash)

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| PR blocked by CODEOWNERS | Request review from correct team via @mention |
| CI fails on lint | Run `npm run lint --fix` or `prettier --write .` locally |
| Force push needed | Rebase your feature branch, don't force push main |
| Merge conflict | `git fetch origin main && git rebase origin/main` |
| Stale branch | Delete and recreate from latest main |
| Failed deployment | Check ArgoCD UI for sync errors |

### Emergency Procedures

#### Critical Production Bug
1. Create hotfix branch: `fix/critical-issue-123`
2. Minimal change to fix issue
3. Fast-track PR (notify on-call)
4. Deploy immediately via git tag
5. Create follow-up PR for proper fix

#### Rollback Production
1. Identify last good tag: `git tag --list`
2. Revert to previous tag: Delete bad tag, ArgoCD auto-syncs
3. Or create new tag pointing to last good commit
4. Monitor rollback in ArgoCD UI

## Metrics & KPIs

Track these metrics for continuous improvement:

- **Lead Time**: Commit to production deployment
- **Deployment Frequency**: How often we deploy to prod
- **Change Failure Rate**: % of deployments causing incidents
- **MTTR**: Mean time to recovery from incidents
- **PR Review Time**: Time from PR open to merge
- **CI Pipeline Duration**: Time for all checks to complete

## References

- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [GitOps Principles](https://opengitops.dev/)
EOF

    git add artifacts/section-00/repo-strategy.md
    git commit -m "docs: add repository and branching strategy" || print_warning "Nothing to commit or already committed"

    print_success "Step 5 completed: Repository strategy documented"
    echo ""
}

# =============================================================================
# Step 6: Create Pull Request Template
# =============================================================================
create_pr_template() {
    print_step "Step 6: Creating Pull Request template"

    cat > .github/PULL_REQUEST_TEMPLATE.md << 'EOF'
# Pull Request

## Description
<!-- Provide a brief description of the changes in this PR -->

## Type of Change
<!-- Mark the relevant option with an 'x' -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] 🔧 Configuration change
- [ ] ♻️ Code refactoring (no functional changes)
- [ ] 🧪 Test addition or update

## Related Issues
<!-- Link to related issues, e.g., "Closes #123" or "Related to #456" -->

Closes #

## Changes Made
<!-- List the main changes made in this PR -->

-
-
-

## Testing
<!-- Describe the tests you ran and how to reproduce them -->

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed
- [ ] CI pipeline passes

### Test Evidence
<!-- Add screenshots, logs, or test results -->

```
# Example: Test command output
$ npm test
✓ All tests passed
```

## Deployment Notes
<!-- Any special deployment considerations? -->

- [ ] Database migration required
- [ ] Configuration changes required
- [ ] Feature flag required
- [ ] Deployment coordination needed

## Checklist
<!-- Mark completed items with an 'x' -->

- [ ] My code follows the project's code style
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## Additional Notes
<!-- Any additional information for reviewers -->

---

**For Reviewers:**
- Review for logic, security, performance, and maintainability
- Check for potential edge cases
- Verify tests cover the changes
- Ensure documentation is updated
EOF

    git add .github/PULL_REQUEST_TEMPLATE.md
    git commit -m "docs: add pull request template" || print_warning "Nothing to commit or already committed"

    print_success "Step 6 completed: PR template created"
    echo ""
}

# =============================================================================
# Step 7: Create Sample CI Workflow
# =============================================================================
create_sample_ci_workflow() {
    print_step "Step 7: Creating sample CI workflow"

    mkdir -p .github/workflows

    cat > .github/workflows/ci.yml << 'EOF'
name: CI Pipeline

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Lint YAML files
        uses: ibiqlik/action-yamllint@v3
        with:
          file_or_dir: .
          config_file: .yamllint.yml

      - name: Lint Markdown files
        uses: DavidAnson/markdownlint-cli2-action@v15
        with:
          globs: '**/*.md'

  validate:
    name: Validate Kubernetes Manifests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Kubernetes tools
        uses: yokawasa/action-setup-kube-tools@v0.11.0
        with:
          kubectl: '1.29.0'
          kustomize: '5.3.0'

      - name: Validate manifests
        run: |
          for dir in apps/*/; do
            if [ -f "$dir/kustomization.yaml" ]; then
              echo "Validating $dir"
              kubectl kustomize "$dir" | kubectl apply --dry-run=client -f -
            fi
          done

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'

  commit-lint:
    name: Conventional Commit Check
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install commitlint
        run: |
          npm install -g @commitlint/cli @commitlint/config-conventional

      - name: Validate commit messages
        run: |
          npx commitlint --from ${{ github.event.pull_request.base.sha }} --to ${{ github.event.pull_request.head.sha }} --verbose
EOF

    # Create yamllint config
    cat > .yamllint.yml << 'EOF'
---
extends: default

rules:
  line-length:
    max: 120
    level: warning
  indentation:
    spaces: 2
  document-start: disable
  comments:
    min-spaces-from-content: 1
EOF

    # Create commitlint config
    cat > .commitlintrc.json << 'EOF'
{
  "extends": ["@commitlint/config-conventional"],
  "rules": {
    "type-enum": [
      2,
      "always",
      [
        "feat",
        "fix",
        "docs",
        "style",
        "refactor",
        "perf",
        "test",
        "chore",
        "revert"
      ]
    ],
    "scope-enum": [
      2,
      "always",
      [
        "argocd",
        "crossplane",
        "backstage",
        "k8s",
        "ci",
        "deps",
        "infra",
        "apps"
      ]
    ],
    "subject-case": [2, "never", ["upper-case"]],
    "subject-empty": [2, "never"],
    "subject-full-stop": [2, "never", "."],
    "header-max-length": [2, "always", 100]
  }
}
EOF

    git add .github/workflows/ci.yml .yamllint.yml .commitlintrc.json
    git commit -m "ci: add GitHub Actions CI pipeline" || print_warning "Nothing to commit or already committed"

    print_success "Step 7 completed: CI workflow created"
    echo ""
}

# =============================================================================
# Step 8: Create Main README
# =============================================================================
create_main_readme() {
    print_step "Step 8: Creating main README"

    cat > README.md << 'EOF'
# Platform GitOps Repository

This repository serves as the **source of truth** for all platform deployments using GitOps principles.

## 🏗️ Repository Structure

```
platform-gitops-repo/
├── apps/                    # Application manifests
│   ├── dev/                # Development environment
│   ├── staging/            # Staging environment
│   └── prod/               # Production environment
├── infrastructure/          # Platform infrastructure
│   ├── argocd/             # ArgoCD bootstrap
│   ├── crossplane/         # Crossplane compositions
│   └── backstage/          # Backstage portal
├── artifacts/               # Documentation artifacts
│   └── section-00/         # Section 00 deliverables
├── .github/                # GitHub configuration
│   ├── workflows/          # CI/CD pipelines
│   ├── CODEOWNERS          # Code ownership
│   └── PULL_REQUEST_TEMPLATE.md
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites
- Git
- kubectl (v1.29+)
- ArgoCD CLI (v2.10+)
- Access to Kubernetes cluster

### Setup
```bash
# Clone this repository
git clone <your-repo-url>
cd platform-gitops-repo

# Verify structure
tree -L 2

# Check CI locally (requires yamllint, kubectl)
yamllint .
kubectl kustomize apps/dev/ --dry-run
```

## 📖 Documentation

- [Repository Strategy](artifacts/section-00/repo-strategy.md) - Multi-repo topology and branching model
- [GitHub Protection Rules](artifacts/section-00/github-protection.md) - Branch protection configuration
- [Commit Conventions](.github/COMMIT_CONVENTION.md) - How to write good commit messages
- [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md) - PR checklist

## 🔄 GitOps Workflow

### For Developers

1. **Create Feature Branch**
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make Changes**
   ```bash
   # Edit Kubernetes manifests
   vim apps/dev/my-app/deployment.yaml

   # Commit with conventional commits
   git add .
   git commit -m "feat(my-app): add health check endpoint"
   ```

3. **Open Pull Request**
   - Push branch: `git push origin feat/my-feature`
   - Open PR on GitHub
   - Wait for CI checks to pass
   - Request review from CODEOWNERS

4. **Merge & Deploy**
   - Squash and merge PR
   - ArgoCD auto-deploys to dev/staging
   - Tag for production: `git tag v1.2.0 && git push --tags`

### For Reviewers

1. Review PR for:
   - Correct Kubernetes manifest syntax
   - Security best practices
   - Resource limits set
   - No secrets committed
   - Conventional commit format

2. Approve if checks pass

## 🌍 Environments

| Environment | Trigger | Auto-Deploy | Purpose |
|-------------|---------|-------------|---------|
| **Dev** | Every commit to `main` | ✅ Yes | Rapid feedback |
| **Staging** | Merge to `main` | ✅ Yes | Pre-prod validation |
| **Prod** | Git tag `v*.*.*` | ❌ Manual | Live traffic |

### Why Manual Production?
- Human checkpoint before production
- Controlled release windows
- Easy rollback (revert tag)
- Compliance requirements

## 🔒 Security

### ✅ Do's
- Use Sealed Secrets or External Secrets Operator
- Set resource limits on all deployments
- Use least-privilege RBAC
- Scan images with Trivy
- Review all PRs

### ❌ Don'ts
- **NEVER** commit secrets (`.env`, `*.key`, `*.pem`)
- Don't bypass CI checks
- Don't force push to `main`
- Don't merge without approval

## 🛠️ Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| PR blocked by CODEOWNERS | Request review: `@platform-engineering-team` |
| CI lint failure | Run `yamllint .` locally |
| Merge conflict | Rebase: `git rebase origin/main` |
| ArgoCD sync failure | Check logs: `argocd app logs <app-name>` |

### Getting Help
- Slack: `#platform-engineering`
- GitHub Issues: Use issue templates
- On-call: Check PagerDuty rotation

## 🎯 CODEOWNERS

Changes to specific paths require approval from:
- `/infrastructure/` → @platform-engineering-team
- `/infrastructure/crossplane/` → @infrastructure-team
- `/apps/team-alpha/` → @team-alpha
- `/apps/prod/` → @platform-engineering-team + @security-team

See [.github/CODEOWNERS](.github/CODEOWNERS) for full list.

## 📊 Metrics

We track:
- **Lead Time**: Commit → Production
- **Deployment Frequency**: Deploys per day
- **Change Failure Rate**: % failed deployments
- **MTTR**: Mean time to recovery

View dashboard: [Grafana Platform Metrics](https://grafana.example.com)

## 🤝 Contributing

1. Read [Repository Strategy](artifacts/section-00/repo-strategy.md)
2. Follow [Commit Conventions](.github/COMMIT_CONVENTION.md)
3. Use [PR Template](.github/PULL_REQUEST_TEMPLATE.md)
4. Get review from CODEOWNERS

## 📚 Related Repositories

- **platform-core**: Backstage developer portal
- **platform-infra**: Crossplane infrastructure
- **app-***: Application repositories (generated from templates)

## 📝 License

Internal use only - Not for public distribution

---

**Platform Engineering Team** | Last Updated: 2026-08-25
EOF

    git add README.md
    git commit -m "docs: add comprehensive README" || print_warning "Nothing to commit or already committed"

    print_success "Step 8 completed: Main README created"
    echo ""
}

# =============================================================================
# Step 9: Create Summary Report
# =============================================================================
create_summary_report() {
    print_step "Step 9: Creating summary report"

    cat > artifacts/section-00/setup-summary.md << 'EOF'
# Day 03 Setup - Summary Report

## ✅ Completed Tasks

### 1. Repository Initialization
- [x] Git repository initialized
- [x] Main branch created
- [x] .gitignore configured (secrets excluded)
- [x] Folder structure created (apps/, infrastructure/)
- [x] Placeholder READMEs added

### 2. Code Ownership
- [x] CODEOWNERS file created
- [x] Team ownership defined
- [x] Protection rules documented

### 3. Documentation
- [x] Repository strategy documented
- [x] Commit convention guide created
- [x] GitHub protection rules documented
- [x] Pull request template created
- [x] Main README created

### 4. CI/CD
- [x] GitHub Actions workflow created
- [x] YAML linting configured
- [x] Kubernetes manifest validation
- [x] Security scanning setup
- [x] Conventional commit checking

### 5. Configuration
- [x] yamllint configuration
- [x] commitlint configuration
- [x] GitHub workflow configuration

## 📁 Files Created

```
platform-gitops-repo/
├── .gitignore
├── .yamllint.yml
├── .commitlintrc.json
├── README.md
├── apps/
│   ├── README.md
│   ├── dev/
│   ├── staging/
│   └── prod/
├── infrastructure/
│   ├── README.md
│   ├── argocd/
│   ├── crossplane/
│   └── backstage/
├── artifacts/
│   └── section-00/
│       ├── github-protection.md
│       ├── repo-strategy.md
│       └── setup-summary.md (this file)
└── .github/
    ├── CODEOWNERS
    ├── COMMIT_CONVENTION.md
    ├── PULL_REQUEST_TEMPLATE.md
    └── workflows/
        └── ci.yml
```

## 🎯 Next Steps

1. **Push to GitHub**
   ```bash
   # Create remote repository on GitHub first, then:
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Configure Branch Protection**
   - Go to GitHub → Settings → Branches
   - Add rule for `main` branch
   - Follow [GitHub Protection Rules](github-protection.md)

3. **Setup GitHub Teams**
   ```
   @platform-engineering-team
   @infrastructure-team
   @security-team
   @team-alpha
   @team-beta
   ```

4. **Validate CI Pipeline**
   - Make a test commit to a feature branch
   - Open PR and verify all checks run
   - Merge after approval

5. **Deploy ArgoCD**
   - Bootstrap ArgoCD in Kubernetes cluster
   - Point ArgoCD to this repository
   - Configure auto-sync policies

## 🔍 Verification Checklist

Run these commands to verify setup:

```bash
# Check Git configuration
git branch --show-current  # Should show: main
git log --oneline          # Should show all setup commits

# Verify folder structure
tree -L 2

# Validate YAML files
yamllint .

# Check CODEOWNERS syntax
cat .github/CODEOWNERS

# Test commit message validation
echo "feat(test): sample commit" | npx commitlint

# Verify all files tracked
git status  # Should show: "nothing to commit, working tree clean"
```

## 📊 Repository Statistics

- **Total Commits**: Run `git rev-list --count main`
- **Files Created**: Run `find . -type f | wc -l`
- **Documentation Pages**: 6 markdown files
- **CI Checks**: 4 jobs configured

## 🚀 Ready for Day 04!

Your GitOps repository is now configured and ready for:
- Kubernetes manifests (Day 04)
- ArgoCD applications (Day 09)
- Crossplane resources (Day 21)

**Section-00 Complete!** 🎉

---

Generated: 2026-08-25
Script: setup-day-03.sh
EOF

    git add artifacts/section-00/setup-summary.md
    git commit -m "docs: add setup summary report" || print_warning "Nothing to commit or already committed"

    print_success "Step 9 completed: Summary report created"
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================
main() {
    echo ""
    echo "============================================================================="
    echo "   Day 03 - Repository & Branching Strategy Setup"
    echo "============================================================================="
    echo ""

    # Check if already in platform-gitops-repo
    if [[ "$(basename $(pwd))" == "platform-gitops-repo" ]]; then
        print_warning "Already inside platform-gitops-repo directory"
        print_warning "Continuing with setup in current directory"
        echo ""
    fi

    # Run all steps
    initialize_gitops_repo
    setup_codeowners
    create_commit_guide
    create_protection_rules_doc
    create_repo_strategy_doc
    create_pr_template
    create_sample_ci_workflow
    create_main_readme
    create_summary_report

    # Final summary
    echo ""
    echo "============================================================================="
    print_success "Setup Complete! 🎉"
    echo "============================================================================="
    echo ""
    echo "📁 Repository Location: $(pwd)"
    echo ""
    echo "✅ Completed:"
    echo "   • Git repository initialized"
    echo "   • Folder structure created"
    echo "   • CODEOWNERS configured"
    echo "   • Documentation written"
    echo "   • CI pipeline configured"
    echo "   • $(git rev-list --count main 2>/dev/null || echo '0') commits made"
    echo ""
    echo "🔍 Verify your setup:"
    echo "   git log --oneline"
    echo "   tree -L 2"
    echo "   yamllint ."
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Push to GitHub: git remote add origin <url> && git push -u origin main"
    echo "   2. Configure branch protection (see artifacts/section-00/github-protection.md)"
    echo "   3. Create GitHub teams (@platform-engineering-team, etc.)"
    echo "   4. Review artifacts/section-00/setup-summary.md"
    echo ""
    echo "📖 Documentation:"
    echo "   • README.md - Overview and quick start"
    echo "   • artifacts/section-00/repo-strategy.md - Detailed strategy"
    echo "   • artifacts/section-00/github-protection.md - Protection rules"
    echo ""
    echo "============================================================================="
    echo ""
}

# Run main function
main "$@"
