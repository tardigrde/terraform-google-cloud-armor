/**
 * Copyright 2025 Google LLC
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

locals {
  pre_configured_rules_no_cond_expr = {
    for name, policy in var.pre_configured_rules : name => {
      expression = "evaluatePreconfiguredWaf('${policy["target_rule_set"]}', {'sensitivity': ${policy["sensitivity_level"]}})"
    } if length(policy["include_target_rule_ids"]) == 0 && length(policy["exclude_target_rule_ids"]) == 0
  }

  pre_configured_rules_include = {
    for name, policy in var.pre_configured_rules : name => {
      target_rule_set         = policy.target_rule_set
      include_target_rule_ids = replace(join(",", policy.include_target_rule_ids), ",", "','")
      sensitivity_level       = policy.sensitivity_level
    } if length(policy["include_target_rule_ids"]) > 0
  }

  pre_configured_rules_include_expr = {
    for name, policy in local.pre_configured_rules_include : name => {
      expression = "evaluatePreconfiguredWaf('${policy["target_rule_set"]}', {'sensitivity': 0, 'opt_in_rule_ids': ['${policy.include_target_rule_ids}']})"
    }
  }

  pre_configured_rules_exclude = {
    for name, policy in var.pre_configured_rules : name => {
      target_rule_set         = policy.target_rule_set
      exclude_target_rule_ids = replace(join(",", policy.exclude_target_rule_ids), ",", "','")
      sensitivity_level       = policy.sensitivity_level
    } if length(policy["include_target_rule_ids"]) == 0 && length(policy["exclude_target_rule_ids"]) > 0
  }

  pre_configured_rules_exclude_expr = {
    for name, policy in local.pre_configured_rules_exclude : name => {
      expression = "evaluatePreconfiguredWaf('${policy["target_rule_set"]}', {'sensitivity': ${policy.sensitivity_level}, 'opt_out_rule_ids': ['${policy.exclude_target_rule_ids}']})"
    }
  }

  pre_configured_rules_expr = merge(
    local.pre_configured_rules_no_cond_expr,
    local.pre_configured_rules_include_expr,
    local.pre_configured_rules_exclude_expr
  )

  threat_intelligence_expr = {
    for name, rule in var.threat_intelligence_rules : name => {
      expression = rule.exclude_ip == null ? "evaluateThreatIntelligence('${rule.feed}')" : "evaluateThreatIntelligence('${rule.feed}', ${rule.exclude_ip})"
    }
  }
}

resource "google_compute_organization_security_policy" "policy" {
  parent      = var.parent
  short_name  = var.name
  description = var.description
  type        = var.type
}

resource "google_compute_organization_security_policy_rule" "security_rules" {
  for_each = var.security_rules

  policy_id   = google_compute_organization_security_policy.policy.id
  priority    = each.value.priority
  action      = each.value.action
  description = each.value.description
  preview     = each.value.preview

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = each.value.src_ip_ranges
    }
  }
}

resource "google_compute_organization_security_policy_rule" "custom_rules" {
  for_each = var.custom_rules

  policy_id   = google_compute_organization_security_policy.policy.id
  priority    = each.value.priority
  action      = each.value.action
  description = each.value.description
  preview     = each.value.preview

  match {
    expr {
      expression = each.value.expression
    }
    versioned_expr = ""
  }
}

resource "google_compute_organization_security_policy_rule" "pre_configured_rules" {
  for_each = var.pre_configured_rules

  policy_id   = google_compute_organization_security_policy.policy.id
  priority    = each.value.priority
  action      = each.value.action
  description = each.value.description
  preview     = each.value.preview

  match {
    expr {
      expression = local.pre_configured_rules_expr[each.key].expression
    }
    versioned_expr = ""
  }
}

resource "google_compute_organization_security_policy_rule" "threat_intelligence_rules" {
  for_each = var.threat_intelligence_rules

  policy_id   = google_compute_organization_security_policy.policy.id
  priority    = each.value.priority
  action      = each.value.action
  description = each.value.description
  preview     = each.value.preview

  match {
    expr {
      expression = local.threat_intelligence_expr[each.key].expression
    }
    versioned_expr = ""
  }
}

resource "google_compute_organization_security_policy_association" "association" {
  count = var.association != null ? 1 : 0

  name              = coalesce(var.association.name, var.name)
  policy_id         = google_compute_organization_security_policy.policy.id
  attachment_id     = var.association.attachment_id
  excluded_projects = var.association.excluded_projects
  excluded_folders  = var.association.excluded_folders
}
