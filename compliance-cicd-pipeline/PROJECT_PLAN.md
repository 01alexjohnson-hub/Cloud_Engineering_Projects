# Project 2: Compliance-as-Code CI/CD Pipeline — Action Plan

## Overview
A GitHub Actions pipeline that scans Terraform against custom NIST 800-53 policy sets and blocks non-compliant deployments before they reach an environment. Uses Project 1's Terraform as the sample code being scanned.

**Repo:** `compliance-cicd-pipeline`
**Cost:** $0 (GitHub Actions free tier, all tools open source)
**Approach:** Hands-on build, ADHD-optimized micro-wins (5-10 min each)
**Learning mode:** Boilerplate/config drafted by Claude, core logic (OPA policies, pipeline stages) written by Alex

---

## Tools & Tech Stack

| Tool | Purpose | Install Method |
|------|---------|----------------|
| GitHub Actions | CI/CD pipeline orchestration | Built into GitHub |
| Checkov | Static analysis for Terraform (800+ built-in checks) | `brew install checkov` |
| Open Policy Agent (OPA) | Custom policy engine for NIST 800-53 rules | `brew install opa` |
| Rego | OPA's policy language — you write the rules in this | Comes with OPA |
| tflint | Terraform linter (catches syntax/style issues) | `brew install tflint` |
| terraform | Plan output for OPA to evaluate | Already installed (v1.15.4) |
| Python 3 | Compliance report generator script | Already installed |
| Git + GitHub | Version control, PR workflows, Actions runtime | Already set up |

---

## Phase 1: Local Tooling & Repo Setup
*Get the tools installed and the repo scaffolded. Every win here is "I ran a command and it worked."*

### Win 1.1 — Install Checkov (5 min)
**You type:**
```bash
brew install checkov
checkov --version
```
**Done when:** Version number prints to terminal.
**What it is:** Checkov is Bridgecrew's open-source scanner. It has 800+ built-in policies for Terraform, CloudFormation, Kubernetes, etc. It knows what "bad Terraform" looks like out of the box.

### Win 1.2 — Install OPA (5 min)
**You type:**
```bash
brew install opa
opa version
```
**Done when:** Version number prints to terminal.
**What it is:** Open Policy Agent is a general-purpose policy engine. Unlike Checkov (which has baked-in rules), OPA lets you write your own rules in a language called Rego. This is where your NIST 800-53 custom policies will live.

### Win 1.3 — Install tflint (5 min)
**You type:**
```bash
brew install tflint
tflint --version
```
**Done when:** Version number prints to terminal.
**What it is:** Terraform linter. Catches syntax errors, deprecated features, and provider-specific issues before you even get to security scanning. It's the first gate in the pipeline.

### Win 1.4 — Create the repo folder and scaffold (5 min)
**You type:**
```bash
cd ~/Desktop/Cloud\ Engineer\ Projects/Cloud\ Engineer
mkdir -p compliance-cicd-pipeline/{.github/workflows,policies/opa,policies/checkov,scripts,docs,terraform-sample}
cd compliance-cicd-pipeline
touch README.md LICENSE .gitignore
```
**Done when:** `tree compliance-cicd-pipeline` shows the folder structure.

### Win 1.5 — Set up .gitignore and LICENSE (5 min)
**Claude drafts, you review and save.**
`.gitignore` covers Terraform state, .terraform dirs, OS files.
`LICENSE` matches Project 1 (Apache 2.0).
**Done when:** Both files have content.

### Win 1.6 — Copy Project 1 Terraform as sample code (10 min)
**You type:**
```bash
cp -r ../fedramp-aws-landing-zone/main.tf terraform-sample/
cp -r ../fedramp-aws-landing-zone/variables.tf terraform-sample/
cp -r ../fedramp-aws-landing-zone/versions.tf terraform-sample/
cp -r ../fedramp-aws-landing-zone/modules/ terraform-sample/modules/
```
**Done when:** `ls terraform-sample/` shows your Project 1 code.
**Why:** This is the Terraform that the pipeline will scan. Real code, not a toy example.

### Win 1.7 — Git init + first commit (5 min)
**You type:**
```bash
git init
git add .
git commit -m "feat: initial repo scaffold with Project 1 Terraform as sample code"
```
**Done when:** Clean commit history with one commit.

**Phase 1 checkpoint:** Tools installed, repo scaffolded, Project 1 code copied in, first commit done.

---

## Phase 2: Run Scanners Locally (Before Any Pipeline)
*Before we automate anything in GitHub Actions, you run every tool manually so you understand what each one does and what its output looks like.*

### Win 2.1 — Run tflint on sample Terraform (5 min)
**You type:**
```bash
cd terraform-sample
tflint --init
tflint
```
**Done when:** You see tflint output (warnings, errors, or all clear). Read through what it found.
**Why manual first:** You need to know what tflint's output looks like before you automate it. Otherwise you're debugging a pipeline AND a tool at the same time.

### Win 2.2 — Run terraform validate (5 min)
**You type:**
```bash
terraform init -backend=false
terraform validate
```
**Done when:** "Success! The configuration is valid." or you see specific errors to understand.
**Note:** `-backend=false` skips the S3 backend config since we're just validating syntax.

### Win 2.3 — Run Checkov on sample Terraform (10 min)
**You type:**
```bash
checkov -d . --framework terraform --compact
```
**Done when:** You see Checkov's pass/fail report. Spend a few minutes reading the output — notice how each check has a CKV ID and maps to a security concern.
**Key learning:** Look at which checks FAIL. These are the kinds of things your pipeline will catch and block.

### Win 2.4 — Run Checkov with NIST 800-53 output (5 min)
**You type:**
```bash
checkov -d . --framework terraform --output json > checkov-results.json
```
**Done when:** JSON file generated. Open it — notice the `check_id`, `check_result`, and `guideline` fields. This is what your compliance report will parse.

### Win 2.5 — Generate a Terraform plan JSON for OPA (10 min)
**You type:**
```bash
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
```
**Done when:** `tfplan.json` exists and you can open it. This is the structured plan that OPA will evaluate against your custom policies.
**Note:** This may require mock provider configs or `-target` flags depending on provider requirements. We'll work through any errors together.

### Win 2.6 — Write and run your first OPA policy (10 min)
**You write this one.** I'll explain the Rego syntax, you type the policy.
A simple policy like "S3 buckets must have encryption enabled" — evaluate it against the plan JSON.
```bash
opa eval -d policies/opa/ -i tfplan.json "data.terraform.deny"
```
**Done when:** OPA returns a result (pass or deny) and you understand why.

### Win 2.7 — Commit local scan results and first policy (5 min)
```bash
git add .
git commit -m "feat: local scanner validation and first OPA policy"
```

**Phase 2 checkpoint:** You've run every tool manually, you know what each output looks like, and you've written your first custom OPA policy. Nothing is automated yet — that's intentional.

---

## Phase 3: Write the Custom NIST 800-53 Policy Set
*This is the core IP of the project. Each win is one policy, mapped to one control.*

### Win 3.1 — Create the policy mapping document (10 min)
**You write this.** A markdown file that maps each OPA policy to its NIST 800-53 control, similar to Project 1's CONTROL_MAPPING.md.
```
| Policy File | Control | What It Checks |
|-------------|---------|----------------|
| s3_encryption.rego | SC-28 | S3 buckets must have encryption |
| ...         | ...     | ...            |
```
**Done when:** `docs/POLICY_MAPPING.md` exists with the structure.

### Win 3.2 through 3.8 — Write individual OPA policies (5-10 min each)
**You write each one.** I'll explain the Rego pattern, you implement it.

Suggested policy set (7 policies covering 7 controls):

| # | Policy | NIST Control | What It Enforces |
|---|--------|-------------|-----------------|
| 3.2 | `s3_encryption.rego` | SC-28 (Protection of Information at Rest) | S3 buckets must have server-side encryption |
| 3.3 | `s3_public_access.rego` | AC-3 (Access Enforcement) | S3 buckets must block public access |
| 3.4 | `iam_no_wildcards.rego` | AC-6 (Least Privilege) | IAM policies must not use wildcard (*) actions |
| 3.5 | `cloudtrail_encryption.rego` | AU-9 (Protection of Audit Information) | CloudTrail must use KMS encryption |
| 3.6 | `vpc_no_default_sg.rego` | SC-7 (Boundary Protection) | Default security groups must have no rules |
| 3.7 | `logging_enabled.rego` | AU-2 (Audit Events) | CloudTrail logging must be enabled |
| 3.8 | `tags_required.rego` | CM-8 (Information System Component Inventory) | All resources must have required tags |

Each win follows the same pattern:
1. Write the .rego file
2. Test it locally with `opa eval`
3. Commit it

### Win 3.9 — Write OPA unit tests for each policy (10 min)
**You write these.** OPA has a built-in test framework.
```bash
opa test policies/opa/ -v
```
**Done when:** All tests pass.

### Win 3.10 — Configure Checkov custom checks (10 min)
**Claude drafts the config, you review.**
A `.checkov.yaml` that enables specific checks relevant to the 800-53 controls we're targeting and skips irrelevant noise.
**Done when:** `checkov -d terraform-sample --config-file .checkov.yaml` runs with a focused check set.

### Win 3.11 — Commit the full policy set (5 min)
```bash
git add .
git commit -m "feat: NIST 800-53 OPA policy set with tests (7 controls)"
```

**Phase 3 checkpoint:** You have a custom policy set with 7 OPA policies mapped to 7 NIST 800-53 controls, each with unit tests, plus a tuned Checkov config. All tested locally.

---

## Phase 4: Build the GitHub Actions Pipeline
*Now we automate what you've been running manually. Each win adds one stage to the pipeline.*

### Win 4.1 — Create the base workflow file (5 min)
**Claude drafts the skeleton, you review.**
`.github/workflows/compliance-scan.yml` — just the trigger config (on PR to main) and a single job that checks out code. No stages yet.
Push to GitHub and confirm the workflow fires.
**Done when:** Green check on a test PR (even though it does nothing useful yet).

### Win 4.2 — Add tflint stage (5 min)
**You add this stage.** I'll give you the YAML block, you paste it into the workflow.
**Done when:** Push, PR, tflint runs in the pipeline.

### Win 4.3 — Add terraform validate stage (5 min)
**Same pattern.** Add the stage, push, confirm it runs.

### Win 4.4 — Add Checkov scan stage (10 min)
**You add this.** Checkov stage using your custom config. Output captured as a job artifact.
**Done when:** Checkov results appear in the Actions log and as a downloadable artifact.

### Win 4.5 — Add terraform plan stage (5 min)
**You add this.** Generates the plan JSON that OPA will evaluate.
**Note:** This uses a mock/stub approach since we're not connecting to real AWS. We'll use plan output with `-target` or provider mocks.

### Win 4.6 — Add OPA evaluation stage (10 min)
**You add this.** OPA evaluates the plan JSON against your policies. This is the hard gate — if any policy returns a deny, the pipeline fails.
**Done when:** OPA stage runs and produces pass/fail results in the Actions log.

### Win 4.7 — Add compliance report generation stage (10 min)
**You write the Python script,** Claude drafts the boilerplate.
`scripts/generate_report.py` — parses Checkov JSON + OPA results into a readable compliance report (markdown).
**Done when:** Report generates as a pipeline artifact.

### Win 4.8 — Add report upload as PR comment (10 min)
**Claude drafts, you review.**
Pipeline posts a summary of the compliance scan results as a comment on the PR. Reviewers see pass/fail at a glance without digging into logs.
**Done when:** PR has an automated comment with the compliance summary.

### Win 4.9 — Full pipeline test + commit (10 min)
Run the full pipeline end-to-end. Fix any integration issues.
```bash
git add .
git commit -m "feat: complete CI/CD compliance pipeline (6 stages)"
```

**Phase 4 checkpoint:** Full working pipeline — lint → validate → Checkov → plan → OPA → report. Automated, runs on every PR.

---

## Phase 5: Demo PRs (Show It Working)
*Create example PRs that demonstrate the pipeline catching violations and passing clean code.*

### Win 5.1 — Create a "bad" Terraform branch (10 min)
**You write this.** Intentionally non-compliant Terraform:
- S3 bucket without encryption
- IAM policy with wildcard actions
- Missing required tags
Push as a PR. Pipeline should FAIL with specific policy violations.
**Done when:** PR shows red ❌ with clear failure reasons.

### Win 5.2 — Create a "fixed" commit on the same PR (10 min)
**You fix the violations** one by one. Push each fix as a separate commit so the commit history tells a story.
**Done when:** PR goes from red ❌ to green ✅.

### Win 5.3 — Create a "clean" Terraform PR (5 min)
**You write this.** A new PR with fully compliant Terraform from the start.
**Done when:** PR shows green ✅ immediately. The contrast with Win 5.1 is the demo.

### Win 5.4 — Screenshot the results (5 min)
Capture screenshots of:
- Failed PR with violation details
- Fixed PR going green
- Compliance report artifact
- PR comment with scan summary
Save to `docs/screenshots/`.

### Win 5.5 — Commit demo artifacts (5 min)
```bash
git add .
git commit -m "docs: demo PRs showing blocked and passing deployments"
```

**Phase 5 checkpoint:** Three demo PRs that tell the story — bad code blocked, fixed code passes, clean code passes. Screenshots captured.

---

## Phase 6: Documentation & Polish
*Make it recruiter-ready.*

### Win 6.1 — Write README.md (10 min)
**You write the first draft,** Claude helps polish. Cover:
- What problem this solves (with your assessor perspective)
- Architecture diagram (pipeline flow)
- Quick Start (how to run locally + how the pipeline works)
- Policy mapping table
- Screenshots of demo PRs

### Win 6.2 — Create architecture diagram (10 min)
**Claude drafts, you review.**
A pipeline flow diagram showing: PR → lint → validate → Checkov → plan → OPA → report → pass/fail.

### Win 6.3 — Write CHANGELOG.md (5 min)
**Claude drafts, you review.** Match Project 1's format.

### Win 6.4 — Final polish pass (10 min)
Review all files, clean up any leftover test artifacts, ensure consistent formatting.

### Win 6.5 — Tag release (5 min)
```bash
git tag -a v1.0.0 -m "v1.0.0: Compliance-as-Code CI/CD Pipeline"
git push origin main --tags
```

**Phase 6 checkpoint:** Project complete. README polished, architecture diagram done, tagged v1.0.0, ready for recruiters.

---

## Summary

| Phase | Wins | Est. Time | What You Have After |
|-------|------|-----------|-------------------|
| 1. Tooling & Repo Setup | 7 | ~40 min | Tools installed, repo scaffolded, P1 code copied |
| 2. Local Scanner Runs | 7 | ~50 min | Every tool run manually, first OPA policy written |
| 3. NIST 800-53 Policy Set | 11 | ~80 min | 7 custom policies with tests + Checkov config |
| 4. GitHub Actions Pipeline | 9 | ~70 min | Full 6-stage automated pipeline |
| 5. Demo PRs | 5 | ~35 min | Blocked + passing PRs with screenshots |
| 6. Documentation & Polish | 5 | ~40 min | Recruiter-ready, tagged v1.0.0 |
| **Total** | **44 wins** | **~5.5 hours** | **Complete project** |

---

## What Could Go Wrong (Pre-Mortem)

| Risk | Mitigation |
|------|-----------|
| `terraform plan` fails without AWS creds in GitHub Actions | Use mock provider or `-generate-config-out` approach; plan against local state only |
| OPA Rego syntax is tricky to learn | Start with the simplest policy (S3 encryption), build pattern recognition |
| Checkov produces overwhelming output | Use `.checkov.yaml` to scope to relevant checks only |
| GitHub Actions free tier minutes run out | Unlikely for this project size, but monitor usage |
| Copying P1 Terraform brings in provider lock issues | Use `-backend=false` and strip provider configs for sample code |

## Rollback Plan
Everything is local + Git. If any phase goes sideways, `git stash` or `git reset` to the last clean commit. No cloud resources to clean up — this entire project runs at $0.
