# Day 02 - Cloud and Cost Guardrails

## Quick Start — Set Up SSO (New Account)

- Enable IAM Identity Center in the AWS Console first (one-time, manual).
- Run `aws configure` and enter your admin access keys (one-time, only for setup).
- Run `./01-create-permission-sets.sh` to create the role.
- Run `./02-create-users-groups.sh` to create the group and user.
- Run `./03-assign-access.sh` to grant the group access to the account.
- Run `./04-setup-profile.sh` to write your SSO profile and log in.
- Run `./05-verify.sh` to confirm your identity and account.
- From now on, log in with `aws sso login --profile northbank` — no more keys needed.
- To undo everything, run `./06-teardown.sh`.

- **Cost Guardrails**: Preventive controls that keep experimentation safe without blocking delivery (budgets, alerts, tagging, account boundaries).

- **Cloud Agnostic Note**: While we use AWS for labs in this course, the principles apply identically to GCP (Billing Alerts) and Azure (Cost Management).

- **Least Privilege IAM**: Grant only the minimum permissions required for course operations. In real enterprise environments, use AWS Organizations Service Control Policies (SCPs) or IAM Permission Boundaries to enforce limits centrally.

- **Tagging Strategy**: Standardized tags make ownership, chargeback, and cleanup automatable.

## 1. Define Mandatory Tagging Standard

```text
Environment: lab | dev | stage | prod
Owner: team-or-person
Project: internal-developer-platform-course
CostCenter: engineering
Lifecycle: temporary | persistent
```

## 2. Set Up AWS Budget via CLI (Hands-On)

Do not skip this. Uncontrolled cloud spend is a major risk when learning infrastructure automation.

```bash
# 1. Create the budget JSON definition
cat > lab-budget.json << 'EOF'
{
    "BudgetLimit": {
        "Amount": "20.00",
        "Unit": "USD"
    },
    "BudgetName": "IDP-Course-Lab-Budget",
    "BudgetType": "COST",
    "TimeUnit": "MONTHLY"
}
EOF

# 2. Create the notification structure
cat > budget-notifications.json << 'EOF'
[
    {
        "Notification": {
            "NotificationType": "ACTUAL",
            "ComparisonOperator": "GREATER_THAN",
            "Threshold": 80,
            "ThresholdType": "PERCENTAGE"
        },
        "Subscribers": [
            {
                "SubscriptionType": "EMAIL",
                "Address": "your-email@example.com"
            }
        ]
    }
]
EOF

# 3. Apply the budget (Replace ACCOUNT_ID with your actual AWS Account ID,
#    and edit budget-notifications.json to use your real email address)
aws budgets create-budget \
    --account-id 123456789012 \
    --budget file://lab-budget.json \
    --notifications-with-subscribers file://budget-notifications.json
```

## 3. Log In via SSO and Assume a Temporary Role (STS)

Real teams don't hand out long-lived IAM access keys. Instead, you authenticate
via AWS SSO (Identity Center), which issues short-lived, auto-expiring
credentials through STS. This section shows that flow end-to-end.

```bash
# 1. One-time setup: configure an SSO profile (interactive - opens a browser)
aws configure sso
# You'll be prompted for:
#   SSO start URL       -> given by your org (e.g. https://your-org.awsapps.com/start)
#   SSO region           -> the region your Identity Center is in
#   Then pick the AWS account + permission set (role) to use
#   Give the profile a name, e.g. "lab-sso"

# 2. Log in (opens browser, authenticates, caches short-lived STS credentials)
aws sso login --profile lab-sso

# 3. Confirm who you are and that it's a temporary assumed role, not root/static keys
aws sts get-caller-identity --profile lab-sso
# Arn should look like: arn:aws:sts::123456789012:assumed-role/<PermissionSet>/<you>
# (NOT arn:aws:iam::...:root and NOT an IAM user ARN)

# 4. (Optional, advanced) Explicitly assume a specific role via STS, e.g. to
#    switch into a scoped-down lab role from a broader SSO session:
aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/lab-guardrails-role \
    --role-session-name idp-course-lab \
    --profile lab-sso
# Returns temporary AccessKeyId / SecretAccessKey / SessionToken (short TTL,
# typically 1 hour by default) - export these as env vars if you need to use
# them outside the CLI profile, or just add --profile to every command instead.
```

**Why this matters:** Notice you never typed a static `aws_access_key_id` /
`aws_secret_access_key` anywhere. That's the point — SSO + STS means every
credential in play expires on its own, so a leaked terminal history or laptop
theft doesn't hand out a permanent key.

## 4. Verify IAM Baseline

```bash
# Verify caller identity to ensure you are not using root credentials
aws sts get-caller-identity
```

## 5. Create a Cost Hygiene Checklist

```bash
mkdir -p artifacts/section-00
cat > artifacts/section-00/cloud-guardrails.md << 'EOF'
# Enterprise Cloud Guardrails

## Budget Rules
- Monthly Budget: $50,000 per Non-Prod AWS Account.
- Alert Thresholds: 50%, 80%, 100%, and AWS Cost Anomaly Detection enabled.

## Tagging Policy
- Mandatory tags: `CostCenter`, `DataClassification`, `Environment`, `OwnerEmail`.
- Enforcement: Untagged resources are flagged by AWS Config and auto-terminated after 24 hours.

## IAM Boundaries
- No persistent IAM users or long-lived access keys allowed. 
- All developer access is via SSO with temporary STS tokens.
- Crossplane will use IAM Roles for Service Accounts (IRSA) with strict permission boundaries.

## Cleanup Cadence
- Automated Lambda scripts destroy all resources tagged with `Environment: ephemeral` every Friday at 6:00 PM local time.
EOF
```

## Operational Insight

The platform team must model responsible cloud behavior. Fast iteration is important, but uncontrolled spend and broad IAM quickly create organizational resistance to platform investment.

## Official Documentation

- [AWS Budgets](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Cost Allocation Tags](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html)
- [AWS Well-Architected Framework - Cost Optimization](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)
