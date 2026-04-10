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

module "hierarchical_security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google//modules/hierarchical-security-policy"
  version = "~> 8.0"

  parent      = "organizations/${var.org_id}"
  name        = "org-denylist-policy-${random_id.suffix.hex}"
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

# IMPORTANT: When you attach a hierarchical security policy to an organization,
# all projects in the organization that inherit the policy will be automatically
# enrolled in Cloud Armor Enterprise Paygo (if not already enrolled in Enterprise Annual).
#
# Auto-enrollment can take up to the next business day to complete.
# During this time, policies are effective without Enterprise costs.
#
# See: https://cloud.google.com/armor/docs/hierarchical-policies-overview#enrollment
