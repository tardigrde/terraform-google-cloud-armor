# Hierarchical Security Policy - Folder Level (Advanced)

This example creates a folder-level hierarchical security policy with WAF rules, Threat Intelligence rules, and custom CEL expressions. The policy is created at the organization level and then associated with a specific folder.

## Features Demonstrated

- **WAF Rules**: SQL injection, XSS, and LFI protection with exclusions
- **Threat Intelligence**: Block known malicious IPs and Tor exit nodes
- **Custom Rules**: `goto_next` action for bypass, geography-based blocking
- **IP-based Rules**: Simple IP denylist and redirect
- **Header Actions**: Add custom headers to requests
- **WAF Exclusions**: Exclude specific URIs from WAF inspection
- **External Association**: Policy association managed outside the module

## Usage

```hcl
module "folder_security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/hierarchical-security-policy"
  version = "~> 8.2"

  parent      = "organizations/${var.org_id}"
  name        = "prod-folder-policy"
  description = "Production folder security policy"

  pre_configured_rules = {
    sqli_level_4 = {
      action            = "deny(403)"
      priority          = 1000
      target_rule_set   = "sqli-v33-stable"
      sensitivity_level = 4
    }
  }

  threat_intelligence_rules = {
    deny_malicious_ips = {
      action      = "deny(403)"
      priority    = 2000
      feed        = "iplist-known-malicious-ips"
    }
  }

  custom_rules = {
    bypass_trusted_proxy = {
      action      = "goto_next"
      priority    = 100
      expression  = "inIpRange(origin.ip, '10.0.0.0/8')"
    }
  }
}

resource "google_compute_organization_security_policy_association" "folder_assoc" {
  name           = "prod-folder-association"
  policy_id      = module.folder_security_policy.policy_id
  attachment_id  = "folders/${var.folder_id}"
}
```

## Cloud Armor Enterprise Enrollment

**IMPORTANT:** When you attach a hierarchical security policy, all projects that inherit the policy will be automatically enrolled in Cloud Armor Enterprise:

| Scenario | Result |
|----------|--------|
| Project already on Enterprise Annual | No change |
| Project on billing account with Annual subscription | Auto-enrolled in Enterprise Annual |
| Project without Annual subscription | Auto-enrolled in Enterprise Paygo |

### Excluding Projects

To exclude projects from the association, use `excluded_projects` on the association resource:

```hcl
resource "google_compute_organization_security_policy_association" "folder_assoc" {
  name              = "prod-folder-association"
  policy_id         = module.folder_security_policy.policy_id
  attachment_id     = "folders/${var.folder_id}"
  excluded_projects = ["projects/project-to-exclude"]
}
```

**Note:** Excluding a project does NOT automatically unenroll it if it was previously enrolled. Manual unenrollment via the console or API is required.

See [Cloud Armor Enterprise enrollment documentation](https://cloud.google.com/armor/docs/hierarchical-policies-overview#enrollment) for more details.

## Rule Evaluation Order

Cloud Armor evaluates security policies in the following order:

1. Organization-level hierarchical security policies
2. Folder-level hierarchical security policies (parent folder → subfolders)
3. Project-level hierarchical security policies
4. Service-level security policies

The `goto_next` action skips the current policy and continues to the next level.

## IAM Permissions

The following IAM roles are required:

| Role | Purpose |
|------|---------|
| `roles/compute.orgSecurityPolicyAdmin` | Create and manage policies |
| `roles/compute.orgSecurityResourceAdmin` | Associate policies with resources |

## Variables

| Name | Description | Type | Required |
|------|-------------|------|----------|
| org_id | The numeric organization ID | string | Yes |
| folder_id | The folder ID to associate the policy with | string | Yes |
| exempt_project_id | Project ID to exclude from the policy association | string | Yes |

## Available Threat Intelligence Feeds

- `iplist-known-malicious-ips` - Known malicious IP addresses
- `iplist-tor-exit-nodes` - Tor exit nodes
- `iplist-open-proxies` - Open proxy servers
- `iplist-any-bots` - Known bot IP addresses
