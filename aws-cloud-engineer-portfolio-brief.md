# AWS Cloud Engineer Portfolio — Project Brief

## Background & Intent

I'm transitioning from a FedRAMP 3PAO assessment background into AWS Cloud Engineering. This portfolio is designed to be sent directly to recruiters alongside my resume — or in place of it — to demonstrate hands-on cloud engineering skills that map to what's actually being hired for in government/federal cloud roles.

**Budget constraint:** Under $10 total over 2 months. All projects must be buildable using AWS Free Tier, LocalStack, local Kubernetes (kind/Minikube), and free CI/CD (GitHub Actions). One brief "proof session" in real AWS (~$10) for screenshots, then tear down.

**My competitive edge:** I already understand NIST 800-53 controls, FedRAMP authorization processes, and federal compliance requirements from the assessor side. Most cloud engineers can build infrastructure but can't connect it to compliance outcomes. This portfolio bridges that gap.

---

## Job Market Analysis (What's Actually Being Asked For)

Based on analysis of three current cloud engineer postings (Anivas Tech, Sensiple/Dice GovCloud role, ClearanceJobs DevSecOps Specialist), here's what keeps appearing:

### Tier 1 — Non-Negotiables
- Terraform (modules, remote state, multi-environment)
- AWS core services (VPC, IAM, EC2, S3, CloudWatch, KMS, Security Hub)
- Docker + Kubernetes/EKS (Helm, RBAC, pod security, cluster lifecycle)
- CI/CD pipelines with security gates (GitHub Actions, GitLab CI, CodePipeline)
- Python and Bash scripting for automation

### Tier 2 — Differentiators
- Compliance-as-code (AWS Config Rules, OPA, Checkov mapped to NIST 800-53)
- Zero Trust Architecture (service mesh, pod security policies, IAM boundaries)
- Monitoring/observability (CloudWatch, Prometheus, Grafana, ELK/EFK)
- Runbooks, architecture diagrams, SOPs, DR documentation

### Tier 3 — Nice-to-Haves That Matter
- Cost optimization (tagging, reserved capacity, right-sizing)
- Cloud migration planning and execution
- AWS certifications (Solutions Architect, Security Specialty)
- GovCloud-specific operational constraints

---

## The Four Projects

### Project 1: FedRAMP-Ready AWS Landing Zone

**Repo name:** `fedramp-aws-landing-zone`

**What it is:** A production-grade Terraform module that deploys a multi-account AWS Organization with FedRAMP-aligned security guardrails baked in from day one.

**What it demonstrates:** IaC proficiency, AWS security services, compliance-to-infrastructure mapping, architectural thinking.

**Key deliverables:**
- Terraform modules for: AWS Organizations + SCPs, CloudTrail (org-wide), GuardDuty, Security Hub (NIST framework), AWS Config Rules mapped to 800-53 controls, centralized logging (S3 + CloudWatch Logs), VPC architecture with proper segmentation, IAM baseline policies and permission boundaries
- A `CONTROL_MAPPING.md` that maps every Terraform resource to the NIST 800-53 control it satisfies
- Architecture diagram (draw.io or Mermaid)
- Successful `terraform plan` output as validation
- Screenshots from one real deploy session (budget: ~$5, then destroy)

**Success criteria:**
- [ ] A recruiter with zero context can read the README and understand what it does and why it matters within 60 seconds
- [ ] `terraform validate` and `terraform plan` pass cleanly
- [ ] At least 15 NIST 800-53 controls are mapped to infrastructure resources
- [ ] Architecture diagram is clear and professional
- [ ] Module is structured for reuse (variables, outputs, sensible defaults)

**Cost:** $0 for development, ~$5 for one proof-of-concept deploy + screenshots

---

### Project 2: Compliance-as-Code CI/CD Pipeline

**Repo name:** `compliance-cicd-pipeline`

**What it is:** A GitHub Actions pipeline that scans Terraform code against custom NIST 800-53 policy sets, blocks non-compliant deployments, and generates a compliance coverage report as a build artifact.

**What it demonstrates:** DevSecOps thinking, CI/CD design, policy-as-code, shift-left security, the ability to translate compliance requirements into automated gates.

**Key deliverables:**
- GitHub Actions workflow: lint (tflint) → validate → security scan (Checkov or tfsec) → custom OPA policy evaluation → terraform plan → compliance report generation
- Custom Checkov or OPA policies mapped to specific 800-53 controls
- Sample Terraform code (can reuse pieces from Project 1) that the pipeline scans
- Compliance report artifact (markdown or HTML) showing: controls checked, pass/fail per control, overall coverage percentage
- Example PR showing a blocked deployment due to a policy violation
- Example PR showing a passing deployment

**Success criteria:**
- [ ] Pipeline runs end-to-end on every PR with zero manual steps
- [ ] At least 10 custom compliance policies are defined and documented
- [ ] A failing PR clearly shows which control was violated and why
- [ ] Compliance report is readable by a non-technical stakeholder
- [ ] Total CI runtime under 5 minutes

**Cost:** $0 (GitHub Actions free tier on public repos, all tools open source)

---

### Project 3: Hardened Kubernetes Cluster with Zero Trust

**Repo name:** `hardened-k8s-zero-trust`

**What it is:** A Terraform-provisioned Kubernetes cluster with defense-in-depth security: network policies, RBAC, pod security standards, service mesh with mTLS, runtime threat detection, and full observability. Built on kind/Minikube locally, architected for EKS deployment.

**What it demonstrates:** Kubernetes security, Zero Trust implementation, observability stack design, IaC for container orchestration.

**Key deliverables:**
- Terraform modules with a `local`/`eks` deployment toggle
- Kubernetes manifests and Helm charts for: namespace isolation + network policies, RBAC roles (least-privilege), pod security standards (restricted), Istio or Linkerd service mesh (mTLS between services), Falco for runtime security monitoring, Prometheus + Grafana dashboards, Fluent Bit log shipping
- A sample multi-service application to demonstrate the security controls in action
- Runbook for incident response (what to do when Falco fires an alert)
- Architecture diagram showing traffic flow, trust boundaries, and monitoring

**Success criteria:**
- [ ] Cluster deploys and runs locally via `make up` or equivalent single command
- [ ] Network policies provably block unauthorized pod-to-pod traffic (demonstrated in README)
- [ ] mTLS is enforced between services (show Kiali or equivalent visualization)
- [ ] Falco detects and alerts on a simulated policy violation
- [ ] Grafana dashboard shows meaningful metrics
- [ ] README clearly states "validated locally on kind, architected for EKS" with the EKS Terraform ready to use

**Cost:** $0 (runs entirely on local machine)

---

### Project 4: Cloud Migration Assessment Tool

**Repo name:** `cloud-migration-planner`

**What it is:** A Python CLI tool that takes a workload inventory (CSV input), analyzes dependencies, recommends AWS service mappings, estimates costs via the AWS Pricing API, and outputs a phased migration plan.

**What it demonstrates:** Migration planning skills, Python scripting, understanding of AWS service selection, cost awareness, documentation quality.

**Key deliverables:**
- Python CLI (Click or Typer) that accepts a CSV of workloads with fields like: name, type (web app, database, file server, etc.), OS, CPU, RAM, storage, dependencies
- Migration strategy recommendation engine (rehost, replatform, refactor) based on workload characteristics
- AWS service mapping (e.g., "SQL Server on Windows VM" → "RDS for SQL Server" or "Aurora PostgreSQL")
- Cost estimation using AWS Pricing API (free, public)
- Output: markdown report with dependency graph (Mermaid), phased timeline, per-workload recommendation, estimated monthly cost
- Sample inventory CSV with 15-20 realistic workloads

**Success criteria:**
- [ ] `pip install` and run with one command
- [ ] Handles edge cases gracefully (missing fields, unknown workload types)
- [ ] Cost estimates are within reasonable range of AWS calculator
- [ ] Output report is professional enough to hand to a client
- [ ] Includes unit tests with 80%+ coverage

**Cost:** $0 (AWS Pricing API is free, everything runs locally)

---

## Recommended Build Order

1. **Project 1** (Landing Zone) — Start here. Highest signal, directly proves core competency, and pieces feed into Project 2.
2. **Project 2** (Compliance Pipeline) — Build second, reuse Terraform from Project 1 as sample code to scan.
3. **Project 3** (Kubernetes) — Third priority. More time-intensive but shows breadth.
4. **Project 4** (Migration Tool) — Final project. Lighter lift, shows a different skill dimension.

## GitHub Profile Presentation

- Pin all four repos
- Each repo needs: a polished README with architecture diagram, a clear "Quick Start" section, a LICENSE (Apache 2.0 or MIT), proper `.gitignore`, tagged releases
- Create a profile README (`username/username` repo) that frames the portfolio narrative: "Cloud engineer with FedRAMP assessment background building compliance-native infrastructure"
- Consistent commit history showing real development progression, not a single massive commit

## What to Send Recruiters

Link to your GitHub profile with a one-liner: "I built these open-source projects to demonstrate how I bridge compliance expertise with hands-on cloud engineering — each one maps directly to skills in your job description." Then reference the specific project that's most relevant to their posting.
