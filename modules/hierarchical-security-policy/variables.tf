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

variable "parent" {
  description = "The parent of this OrganizationSecurityPolicy in the Cloud Resource Hierarchy. Format: 'organizations/{organization_id}' or 'folders/{folder_id}'"
  type        = string

  validation {
    condition     = can(regex("^(organizations|folders)/[0-9]+$", var.parent))
    error_message = "Parent must be in the format 'organizations/{id}' or 'folders/{id}' where id is numeric."
  }
}

variable "name" {
  description = "Short name of the security policy. The name should be unique in the organization in which the security policy is created."
  type        = string
}

variable "description" {
  description = "An optional description of this security policy. Max size is 2048."
  type        = string
  default     = null
}

variable "type" {
  description = "The type indicates the intended use of the security policy. Possible values: CLOUD_ARMOR, CLOUD_ARMOR_EDGE, CLOUD_ARMOR_INTERNAL_SERVICE, CLOUD_ARMOR_NETWORK."
  type        = string
  default     = "CLOUD_ARMOR"

  validation {
    condition     = contains(["CLOUD_ARMOR", "CLOUD_ARMOR_EDGE", "CLOUD_ARMOR_INTERNAL_SERVICE", "CLOUD_ARMOR_NETWORK"], var.type)
    error_message = "Type must be one of: CLOUD_ARMOR, CLOUD_ARMOR_EDGE, CLOUD_ARMOR_INTERNAL_SERVICE, CLOUD_ARMOR_NETWORK."
  }
}

variable "security_rules" {
  description = "Map of security rules matching on source IP addresses."
  type = map(object({
    action        = string
    priority      = number
    description   = optional(string)
    preview       = optional(bool, false)
    src_ip_ranges = list(string)
  }))
  default = {}
}

variable "custom_rules" {
  description = "Map of custom rules using CEL expressions (includes WAF and Threat Intelligence via expression)."
  type = map(object({
    action      = string
    priority    = number
    description = optional(string)
    preview     = optional(bool, false)
    expression  = string
  }))
  default = {}
}

variable "pre_configured_rules" {
  description = "Map of preconfigured WAF rules with Sensitivity levels."
  type = map(object({
    action                  = string
    priority                = number
    description             = optional(string)
    preview                 = optional(bool, false)
    target_rule_set         = string
    sensitivity_level       = optional(number, 4)
    include_target_rule_ids = optional(list(string), [])
    exclude_target_rule_ids = optional(list(string), [])
  }))
  default = {}
}

variable "threat_intelligence_rules" {
  description = "Map of Threat Intelligence rules. Requires Cloud Armor Enterprise."
  type = map(object({
    action      = string
    priority    = number
    description = optional(string)
    preview     = optional(bool, false)
    feed        = string
    exclude_ip  = optional(string)
  }))
  default = {}
}

variable "association" {
  description = "Association configuration to attach policy to an organization, folder, or project. If provided, association is created within the module. Set to null to manage associations outside the module using the policy_id output. IMPORTANT: When you attach a hierarchical security policy, all projects that inherit the policy will be automatically enrolled in Cloud Armor Enterprise. See: https://cloud.google.com/armor/docs/hierarchical-policies-overview#enrollment. Note: excluded_folders is only valid when attachment_id points to an organization; it will be rejected by the API for folder-level attachments."
  type = object({
    name              = optional(string)
    attachment_id     = string
    excluded_projects = optional(list(string), [])
    excluded_folders  = optional(list(string), [])
  })
  default = null
}
