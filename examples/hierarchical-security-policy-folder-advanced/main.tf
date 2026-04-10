/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "random_id" "suffix" {
  byte_length = 4
}

module "folder_security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/hierarchical-security-policy"
  version = "~> 8.0"

  parent      = "organizations/${var.org_id}"
  name        = "prod-folder-policy-${random_id.suffix.hex}"
  description = "Production folder security policy with WAF and Threat Intelligence rules"

  pre_configured_rules = {
    sqli_level_4 = {
      action            = "deny(403)"
      priority          = 1000
      target_rule_set   = "sqli-v33-stable"
      sensitivity_level = 4
      description       = "SQL injection protection at sensitivity level 4"
    }

    xss_level_3 = {
      action            = "deny(403)"
      priority          = 1001
      target_rule_set   = "xss-v33-stable"
      sensitivity_level = 3
      description       = "XSS protection at sensitivity level 3"
    }

    lfi_with_exclude = {
      action                  = "deny(403)"
      priority                = 1002
      target_rule_set         = "lfi-v33-stable"
      sensitivity_level       = 4
      description             = "LFI protection with excluded rules"
      exclude_target_rule_ids = ["owasp-crs-v030301-id932110-lfi"]
    }
  }

  threat_intelligence_rules = {
    deny_malicious_ips = {
      action      = "deny(403)"
      priority    = 2000
      feed        = "iplist-known-malicious-ips"
      description = "Block known malicious IP addresses"
    }

    deny_tor_exit = {
      action      = "deny(403)"
      priority    = 2001
      feed        = "iplist-tor-exit-nodes"
      description = "Block Tor exit nodes"
      preview     = true
    }
  }

  custom_rules = {
    bypass_trusted_proxy = {
      action      = "goto_next"
      priority    = 100
      description = "Skip this policy for trusted upstream proxy IPs"
      expression  = "inIpRange(origin.ip, '10.0.0.0/8')"
    }

    deny_specific_regions = {
      action      = "deny(403)"
      priority    = 3000
      description = "Deny traffic from specific geographic regions"
      expression  = "'[CN,RU]'.contains(origin.region_code)"
    }
  }

  security_rules = {
    deny_known_bad_ips = {
      action        = "deny(403)"
      priority      = 4000
      description   = "Deny known bad IP ranges"
      src_ip_ranges = ["198.51.100.0/24"]
    }
  }
}

# IMPORTANT: When you attach a hierarchical security policy to a folder,
# all projects in the folder that inherit the policy will be automatically
# enrolled in Cloud Armor Enterprise Paygo (if not already enrolled).
#
# To exclude projects from the policy, use excluded_projects parameter:
#   excluded_projects = ["projects/project-id-to-exclude"]
#
# If a project was previously enrolled, excluding it does NOT
# automatically unenroll it - manual unenrollment is required.
#
# See: https://cloud.google.com/armor/docs/hierarchical-policies-overview#enrollment
resource "google_compute_organization_security_policy_association" "folder_assoc" {
  name              = "prod-folder-association-${random_id.suffix.hex}"
  policy_id         = module.folder_security_policy.policy_id
  attachment_id     = "folders/${var.folder_id}"
  excluded_projects = ["projects/${var.exempt_project_id}"]
}
