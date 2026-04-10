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

output "policy" {
  description = "The organization security policy resource"
  value       = google_compute_organization_security_policy.policy
}

output "policy_id" {
  description = "The ID of the organization security policy. Use this to create associations outside the module."
  value       = google_compute_organization_security_policy.policy.id
}

output "security_rules" {
  description = "Map of security rules created"
  value       = google_compute_organization_security_policy_rule.security_rules
}

output "custom_rules" {
  description = "Map of custom rules created"
  value       = google_compute_organization_security_policy_rule.custom_rules
}

output "pre_configured_rules" {
  description = "Map of preconfigured WAF rules created"
  value       = google_compute_organization_security_policy_rule.pre_configured_rules
}

output "threat_intelligence_rules" {
  description = "Map of threat intelligence rules created"
  value       = google_compute_organization_security_policy_rule.threat_intelligence_rules
}

output "association" {
  description = "The association resource (if created within module)"
  value       = var.association != null ? google_compute_organization_security_policy_association.association[0] : null
}
