# Hierarchical Security Policy - Organization Level (Simple)

This example creates a simple organization-level hierarchical security policy with IP-based deny rules.

## Usage

```hcl
module "hierarchical_security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/hierarchical-security-policy"
  version = "~> 8.2"

  parent      = "organizations/${var.org_id}"
  name        = "org-denylist-policy"
  description = "Organization-wide IP denylist security policy"

  security_rules = {
    deny_malicious_ips = {
      action        = "deny(403)"
      priority      = 1000
      description   = "Deny known malicious IP ranges"
      src_ip_ranges = ["192.0.2.0/24", "203.0.113.0/24"]
    }
  }

  association = {
    attachment_id = "organizations/${var.org_id}"
  }
}
```

## Cloud Armor Enterprise Enrollment

**IMPORTANT:** When you attach a hierarchical security policy to an organization, all projects in the organization that inherit the policy will be automatically enrolled in Cloud Armor Enterprise:

| Scenario | Result |
|----------|--------|
| Project already on Enterprise Annual | No change |
| Project on billing account with Annual subscription | Auto-enrolled in Enterprise Annual |
| Project without Annual subscription | Auto-enrolled in Enterprise Paygo |

- Auto-enrollment can take up to the next business day
- During enrollment, policies are effective without Enterprise costs
- You cannot remove a project from Cloud Armor Enterprise while it has inherited hierarchical security policies

See [Cloud Armor Enterprise enrollment documentation](https://cloud.google.com/armor/docs/hierarchical-policies-overview#enrollment) for more details.

## IAM Permissions

The following IAM roles are required:

- `roles/compute.orgSecurityPolicyAdmin` - To create and manage the policy
- `roles/compute.orgSecurityResourceAdmin` - To associate the policy

## Variables

| Name | Description | Type | Required |
|------|-------------|------|----------|
| org_id | The numeric organization ID | string | Yes |
