# Cloud Armor Terraform Module for Hierarchical Security Policy

This module creates [hierarchical security policies](https://cloud.google.com/armor/docs/hierarchical-policies-overview) that extend Cloud Armor protection beyond individual projects. Hierarchical security policies are attached at the organization, folder, or project level, allowing centralized security enforcement across your Google Cloud environment.

## Cloud Armor Enterprise Enrollment

**IMPORTANT:** When you attach a hierarchical security policy to an organization or folder, all projects that inherit the policy will be automatically enrolled in Cloud Armor Enterprise if they are not already enrolled.

### Enrollment Behavior

| Scenario | Result |
|----------|--------|
| Project already on Enterprise Annual | No change |
| Project on billing account with Annual subscription | Auto-enrolled in Enterprise Annual |
| Project without Annual subscription | Auto-enrolled in Enterprise Paygo |

### Key Points

- Auto-enrollment can take up to the next business day to complete
- During enrollment, hierarchical security policies are effective without Enterprise costs
- Projects are auto-enrolled only when at least one backend service for global external load balancers uses HTTP, HTTPS, HTTP2, H2C, or GRPC
- You cannot remove a project from Cloud Armor Enterprise while it has inherited hierarchical security policies
- Excluding a project from the policy association does **not** automatically unenroll it from Cloud Armor Enterprise

### Excluding Projects

To exclude specific projects from a hierarchical security policy (and avoid auto-enrollment), create the association resource outside the module and use the `excluded_projects` or `excluded_folders` fields:

```hcl
resource "google_compute_organization_security_policy_association" "assoc" {
  name              = "my-association"
  policy_id         = module.hierarchical_security_policy.policy_id
  attachment_id     = "organizations/${var.org_id}"
  excluded_projects = ["projects/project-to-exclude"]
}
```

For more information, see the [Google Cloud Armor Enterprise enrollment documentation](https://cloud.google.com/armor/docs/hierarchical-policies-overview#enrollment).

## Features

### Supported Features

| Feature | Supported |
|---------|-----------|
| WAF Rules (via `evaluatePreconfiguredWaf()`) | Yes |
| Threat Intelligence (via `evaluateThreatIntelligence()`) | Yes |
| Custom CEL expressions | Yes |
| IP-based rules | Yes |
| `goto_next` action | Yes |
| Redirect (EXTERNAL_302) | Planned (not yet in provider) |
| Header actions | Planned (not yet in provider) |
| WAF exclusions | Planned (not yet in provider) |

### Not Supported (Compared to Service-Level Policies)

- Rate limiting (throttle, rate_based_ban)
- GOOGLE_RECAPTCHA redirect type
- Adaptive Protection
- Default rule (priority 2147483647)
- JSON parsing / log level advanced options
- reCAPTCHA session/action tokens

> **Note:** `redirect_options`, `header_action`, and `preconfigured_waf_config` are defined in the
> [magic-modules schema](https://github.com/GoogleCloudPlatform/magic-modules/tree/main/mmv1/products/compute/OrganizationSecurityPolicyRule.yaml)
> but not yet available in the published Terraform provider. They will be added to this module
> once the provider supports them.

## Module Format

```hcl
module "hierarchical_security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/hierarchical-security-policy"
  version = "~> 8.2"

  parent      = "organizations/${var.org_id}"
  name        = "org-security-policy"
  description = "Organization-wide security policy"

  security_rules = {
    deny_malicious_ips = {
      action        = "deny(403)"
      priority      = 1000
      src_ip_ranges = ["192.0.2.0/24"]
    }
  }

  pre_configured_rules = {
    sqli_level_4 = {
      action            = "deny(403)"
      priority          = 2000
      target_rule_set   = "sqli-v33-stable"
      sensitivity_level = 4
    }
  }

  association = {
    attachment_id = "organizations/${var.org_id}"
  }
}
```

## Usage

There are examples included in the [examples](https://github.com/GoogleCloudPlatform/terraform-google-cloud-armor/tree/main/examples) folder.

### Simple Example

```hcl
module "org_security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/hierarchical-security-policy"
  version = "~> 8.2"

  parent      = "organizations/${var.org_id}"
  name        = "org-denylist-policy"
  description = "Organization-wide IP denylist"

  security_rules = {
    deny_malicious_ips = {
      action        = "deny(403)"
      priority      = 1000
      description   = "Deny known malicious IP ranges"
      src_ip_ranges = ["192.0.2.0/24", "203.0.113.0/24"]
    }
  }

  # Association creates attachment to organization
  # IMPORTANT: All projects will be auto-enrolled in Cloud Armor Enterprise
  association = {
    attachment_id = "organizations/${var.org_id}"
  }
}
```

### Advanced Example with WAF and Threat Intelligence

```hcl
module "folder_security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/hierarchical-security-policy"
  version = "~> 8.2"

  parent      = "organizations/${var.org_id}"
  name        = "prod-folder-policy"
  description = "Production folder security policy"

  # Use goto_next to bypass for trusted IPs
  custom_rules = {
    bypass_trusted = {
      action      = "goto_next"
      priority    = 100
      description = "Skip policy for trusted proxy"
      expression  = "inIpRange(origin.ip, '10.0.0.0/8')"
    }
  }

  # WAF Rules
  pre_configured_rules = {
    sqli_level_4 = {
      action            = "deny(403)"
      priority          = 1000
      target_rule_set   = "sqli-v33-stable"
      sensitivity_level = 4
    }
  }

  # Threat Intelligence
  threat_intelligence_rules = {
    deny_malicious = {
      action      = "deny(403)"
      priority    = 2000
      feed        = "iplist-known-malicious-ips"
    }
  }
}

# Manage association externally
resource "google_compute_organization_security_policy_association" "folder_assoc" {
  name           = "prod-folder-association"
  policy_id      = module.folder_security_policy.policy_id
  attachment_id  = "folders/${var.folder_id}"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| association | Association configuration to attach policy to an organization, folder, or project. If provided, association is created within the module. Set to null to manage associations outside the module using the policy\_id output. IMPORTANT: When you attach a hierarchical security policy, all projects that inherit the policy will be automatically enrolled in Cloud Armor Enterprise. See: https://cloud.google.com/armor/docs/hierarchical-policies-overview#enrollment | <pre>object({<br>    name = optional(string)<br>    attachment_id = string<br>    excluded_projects = optional(list(string), [])<br>    excluded_folders = optional(list(string), [])<br>  })</pre> | `null` | no |
| custom\_rules | Map of custom rules using CEL expressions (includes WAF and Threat Intelligence via expression). | <pre>map(object({<br>    action = string<br>    priority = number<br>    description = optional(string)<br>    preview = optional(bool, false)<br>    expression = string<br>  }))</pre> | `{}` | no |
| description | An optional description of this security policy. Max size is 2048. | `string` | `null` | no |
| name | Short name of the security policy. The name should be unique in the organization in which the security policy is created. | `string` | n/a | yes |
| parent | The parent of this OrganizationSecurityPolicy in the Cloud Resource Hierarchy. Format: 'organizations/{organization\_id}' or 'folders/{folder\_id}' | `string` | n/a | yes |
| pre\_configured\_rules | Map of preconfigured WAF rules with Sensitivity levels. | <pre>map(object({<br>    action = string<br>    priority = number<br>    description = optional(string)<br>    preview = optional(bool, false)<br>    target_rule_set = string<br>    sensitivity_level = optional(number, 4)<br>    include_target_rule_ids = optional(list(string), [])<br>    exclude_target_rule_ids = optional(list(string), [])<br>  }))</pre> | `{}` | no |
| security\_rules | Map of security rules matching on source IP addresses. | <pre>map(object({<br>    action = string<br>    priority = number<br>    description = optional(string)<br>    preview = optional(bool, false)<br>    src_ip_ranges = list(string)<br>  }))</pre> | `{}` | no |
| threat\_intelligence\_rules | Map of Threat Intelligence rules. Requires Cloud Armor Enterprise. | <pre>map(object({<br>    action = string<br>    priority = number<br>    description = optional(string)<br>    preview = optional(bool, false)<br>    feed = string<br>    exclude_ip = optional(string)<br>  }))</pre> | `{}` | no |
| type | The type indicates the intended use of the security policy. Possible values: CLOUD\_ARMOR, CLOUD\_ARMOR\_EDGE, CLOUD\_ARMOR\_INTERNAL\_SERVICE, CLOUD\_ARMOR\_NETWORK. | `string` | `"CLOUD_ARMOR"` | no |

## Outputs

| Name | Description |
|------|-------------|
| association | The association resource (if created within module) |
| custom\_rules | Map of custom rules created |
| policy | The organization security policy resource |
| policy\_id | The ID of the organization security policy. Use this to create associations outside the module. |
| pre\_configured\_rules | Map of preconfigured WAF rules created |
| security\_rules | Map of security rules created |
| threat\_intelligence\_rules | Map of threat intelligence rules created |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Rule Types

### security_rules

IP-based rules using source IP ranges.

| Field | Description | Required |
|-------|-------------|----------|
| action | Action: `allow`, `deny`, `deny(403)`, `deny(404)`, `deny(502)`, `goto_next` | Yes |
| priority | Rule priority (0-2147483647, lower = higher priority) | Yes |
| src_ip_ranges | List of source IP ranges in CIDR format | Yes |
| description | Rule description | No |
| preview | Preview mode (action not enforced) | No |

### custom_rules

Rules using CEL expressions. Supports WAF, Threat Intelligence, and custom matching.

| Field | Description | Required |
|-------|-------------|----------|
| action | Action: `allow`, `deny`, `deny(403)`, `deny(404)`, `deny(502)`, `goto_next` | Yes |
| priority | Rule priority (0-2147483647) | Yes |
| expression | CEL expression | Yes |
| description | Rule description | No |
| preview | Preview mode | No |

### pre_configured_rules

Convenience wrapper for WAF rules. Module builds the `evaluatePreconfiguredWaf()` expression.

| Field | Description | Required |
|-------|-------------|----------|
| action | Action | Yes |
| priority | Rule priority | Yes |
| target_rule_set | WAF rule set (e.g., `sqli-v33-stable`) | Yes |
| sensitivity_level | Sensitivity 0-4 (default: 4) | No |
| include_target_rule_ids | Opt-in specific rules | No |
| exclude_target_rule_ids | Opt-out specific rules | No |
| description | Rule description | No |
| preview | Preview mode | No |

### threat_intelligence_rules

Threat Intelligence feed rules. Requires Cloud Armor Enterprise.

| Field | Description | Required |
|-------|-------------|----------|
| action | Action | Yes |
| priority | Rule priority | Yes |
| feed | Feed name (e.g., `iplist-known-malicious-ips`) | Yes |
| exclude_ip | IPs to exclude from feed | No |
| description | Rule description | No |
| preview | Preview mode | No |

### Available Threat Intelligence Feeds

- `iplist-known-malicious-ips` - Known malicious IP addresses
- `iplist-tor-exit-nodes` - Tor exit nodes
- `iplist-open-proxies` - Open proxy servers
- `iplist-any-bots` - Known bot IP addresses

## Association

The policy must be associated with an organization, folder, or project to take effect.

### Association Within Module

```hcl
association = {
  name          = "my-association"           # Optional, defaults to policy name
  attachment_id = "organizations/123456789"  # or "folders/123" or "projects/my-project"
}
```

### Association Outside Module

Use the `policy_id` output:

```hcl
resource "google_compute_organization_security_policy_association" "assoc" {
  name           = "my-association"
  policy_id      = module.hierarchical_security_policy.policy_id
  attachment_id  = "folders/${var.folder_id}"
}
```

To exclude projects or folders from the association:

```hcl
resource "google_compute_organization_security_policy_association" "assoc" {
  name              = "my-association"
  policy_id         = module.hierarchical_security_policy.policy_id
  attachment_id     = "organizations/${var.org_id}"
  excluded_projects = ["projects/project-to-exclude"]  # Optional
  # excluded_folders = ["folders/folder-to-exclude"]    # Optional, org-level only
}
```

## goto_next Action

The `goto_next` action is unique to hierarchical policies. It skips the current policy and continues evaluation at the next level:

1. Organization policies → Folder policies → Project policies → Service-level policies

Use `goto_next` to create bypass rules:

```hcl
custom_rules = {
  bypass_trusted_ips = {
    action      = "goto_next"
    priority    = 100
    expression  = "inIpRange(origin.ip, '10.0.0.0/8')"
  }
}
```

## IAM Permissions

### Required Roles

| Operation | Role |
|-----------|------|
| Create/Modify/Delete Policy | `roles/compute.orgSecurityPolicyAdmin` |
| Associate Policy | `roles/compute.orgSecurityResourceAdmin` + `roles/compute.orgSecurityPolicyAdmin` or `roles/compute.orgSecurityPolicyUser` |

## Requirements

### Software

- [Terraform][terraform] v1.3+
- [Terraform Provider for GCP][terraform-provider-gcp] plugin v7.17+

### Project Setup

The project must be part of a Google Cloud Organization. Hierarchical security policies are not available for projects outside an organization.

[terraform]: https://www.terraform.io/
[terraform-provider-gcp]: https://registry.terraform.io/providers/hashicorp/google/
