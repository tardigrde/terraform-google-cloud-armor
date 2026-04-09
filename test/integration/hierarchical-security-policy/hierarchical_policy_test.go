// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package hierarchical_security_policy

import (
	"fmt"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

func TestHierarchicalSecurityPolicy(t *testing.T) {
	casp := tft.NewTFBlueprintTest(t)

	casp.DefineVerify(func(assert *assert.Assertions) {
		orgId := casp.GetTFSetupStringOutput("org_id")
		policyId := casp.GetStringOutput("policy_id")

		policy := gcloud.Run(t, fmt.Sprintf("compute org-security-policies describe %s --organization %s", policyId, orgId))
		for _, p := range policy.Array() {
			assert.Equal("CLOUD_ARMOR", p.Get("type").String(), "has expected type")
			assert.Contains(p.Get("shortName").String(), "org-denylist-policy", "has expected short name prefix")
		}

		rule := gcloud.Run(t, fmt.Sprintf("compute org-security-policies rules describe 1000 --security-policy %s --organization %s", policyId, orgId))
		for _, r := range rule.Array() {
			assert.Equal("deny(403)", r.Get("action").String(), "priority 1000 rule has expected action")
			assert.Equal("Deny known malicious IP ranges", r.Get("description").String(), "priority 1000 rule has expected description")
			assert.Equal("SRC_IPS_V1", r.Get("match.versionedExpr").String(), "priority 1000 rule has expected versioned expr")
			srcIpRanges := r.Get("match.config.srcIpRanges").Array()
			assert.Equal(2, len(srcIpRanges), "priority 1000 rule has expected number of IP ranges")
		}
	})
	casp.Test()
}
