# AWS Cloud Engineer Portfolio

## The Short Version

I spent the last few years at various 3PAO's assessing AWS/Azure/GCP environments for FedRAMP. I got really good at finding what was wrong with other people's infrastructure. At some point I realized I wanted to be the one building it right in the first place.

So that's what this is. Four projects that show I can actually engineer cloud infrastructure, not just audit it. The FedRAMP background isn't baggage, it's the whole point. I already know what NIST 800-53 controls look like when they're implemented well (and when they're not), so everything I build starts with security and compliance baked in from the first commit.

I built all of this on a near zero budget. Free tier, local tools, one short proof deploy per project for screenshots, then tear it down. The constraint was intentional with the idea that if I can build production grade infrastructure on a free tier, then working in a real production environment with allocated budgets and teams pulling together would translate smoothly.

---

## What I Keep Seeing on Job Boards

I've been watching cloud engineer postings for a while now, especially in the federal and GovCloud space. Certain skills show up in almost every listing, and I wanted to make sure these projects cover them deliberately, not by accident.

### What every posting asks for
- Terraform (modules, remote state, multi-environment)
- AWS core (VPC, IAM, EC2, S3, CloudWatch, KMS, Security Hub)
- Docker + Kubernetes/EKS (Helm, RBAC, pod security)
- CI/CD with security gates (GitHub Actions, GitLab CI, CodePipeline)
- Python and Bash scripting

### Where I think I can differentiate
- Compliance-as-code (Config Rules, OPA, Checkov mapped to NIST 800-53)
- Zero Trust (service mesh, pod security, IAM boundaries)
- Monitoring and observability (CloudWatch, Prometheus, Grafana)
- Runbooks, architecture docs, SOPs

Most engineers can check the first box. Not many can tie their infrastructure decisions back to specific compliance controls and explain why it matters. That's the gap I'm building into.

### Skills I'm also working toward
- Cost optimization and tagging strategy
- Cloud migration planning
- AWS certs (I have the AI Practitioner, Solutions Architect is next)
- GovCloud operational experience

---

## The Four Projects

### Project 1: FedRAMP-Ready AWS Landing Zone

**Repo:** `fedramp-aws-landing-zone` | **Status:** Complete

This is the flagship. A full Terraform landing zone that deploys a multi-account AWS Organization with FedRAMP security guardrails. 77 resources across 7 modules, every single one mapped to a NIST 800-53 control.

I deployed it to a real AWS account, ran Security Hub's automated NIST 800-53 checks (scored 44%, which is expected for free tier since the remaining controls need production services like ALB/TLS, WAF, and KMS CMKs), captured screenshots, then destroyed everything.

What it covers:
- AWS Organizations with 5 SCPs that even account admins can't override
- Org wide CloudTrail, GuardDuty, Security Hub with NIST 800-53 standards
- AWS Config with 6 managed rules (encryption, MFA, SSH)
- VPC with 3 tier security group chaining (ALB > App > Data)
- IAM permission boundaries that cap what any role can do
- Centralized encrypted logging with lifecycle to Glacier
- A CONTROL_MAPPING.md that maps every resource to its NIST control

**Cost:** $0 dev, ~$5 proof deploy

---

### Project 2: Compliance-as-Code CI/CD Pipeline

**Repo:** `compliance-cicd-pipeline` | **Status:** Not started

This one came from seeing how many assessment findings trace back to the same problem: somebody deployed something that never should have passed a policy check. A GitHub Actions pipeline that scans Terraform against custom NIST 800-53 policy sets and blocks non-compliant deployments before they ever reach an environment.

The plan is to reuse the Terraform from Project 1 as the sample code being scanned, so it builds on what's already done.

What it covers:
- Full pipeline: lint > validate > security scan (Checkov) > OPA policies > plan > compliance report
- Custom policies mapped to specific 800-53 controls
- Example PRs showing blocked and passing deployments
- Reports readable by someone who isn't an engineer

**Cost:** $0 (GitHub Actions free tier, all tools open source)

---

### Project 3: Hardened Kubernetes Cluster with Zero Trust

**Repo:** `hardened-k8s-zero-trust` | **Status:** Not started

Kubernetes keeps showing up in every posting I look at, and most of the implementations I've assessed have weak network policies and overly permissive RBAC. I wanted to build one the right way. Defense-in-depth from the ground up: network policies, RBAC, pod security, service mesh with mTLS, Falco for runtime detection, and Prometheus/Grafana for observability. Runs on kind locally, architected so the EKS toggle is ready to go.

What it covers:
- Namespace isolation and network policies that provably block unauthorized traffic
- RBAC with least-privilege roles
- Istio or Linkerd for mTLS between services
- Falco for runtime security alerts
- Grafana dashboards with real metrics
- Incident response runbook (what to do when Falco fires)

**Cost:** $0 (runs entirely local)

---

### Project 4: Cloud Migration Assessment Tool

**Repo:** `cloud-migration-planner` | **Status:** Not started

This one comes from a different angle. During assessments I'd see organizations mid-migration with no real plan for how workloads were going to map to AWS services, what the dependencies looked like, or what it was going to cost. A Python CLI that takes a workload inventory (CSV), analyzes dependencies, recommends AWS service mappings, estimates costs via the AWS Pricing API, and outputs a phased migration plan.

What it covers:
- Python CLI (Click or Typer) with clean error handling
- Migration strategy engine (rehost, replatform, refactor)
- AWS service mapping based on workload characteristics
- Cost estimation using the public AWS Pricing API
- Professional output you could actually hand to a client
- Unit tests with 80%+ coverage

**Cost:** $0 (Pricing API is free, everything local)

---

## Build Order

1. **Landing Zone** (done). Highest signal, proves core competency, and the Terraform feeds into Project 2.
2. **Compliance Pipeline** next. Reuses Project 1 code, shows DevSecOps thinking.
3. **Kubernetes** third. More time but shows breadth into container orchestration.
4. **Migration Tool** last. Different skill dimension, lighter lift.

## GitHub Presentation

- Pin all four repos
- Each one gets a polished README, architecture diagram, Quick Start, LICENSE, proper .gitignore, tagged releases
- Profile README that frames the narrative: compliance background + hands-on engineering
- Real commit history showing development progression, not one giant commit dump

## What to Say to Recruiters

Link to the GitHub profile. Something like: "I built these to show how compliance expertise and cloud engineering work together. Each project maps to skills in your posting." Then point them at whichever project is most relevant to the role.
