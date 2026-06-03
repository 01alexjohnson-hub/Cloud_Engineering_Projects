#!/usr/bin/env python3
"""
Compliance Report Generator
Parses Checkov JSON and OPA results into a markdown compliance report.
"""
import json
import sys
from datetime import datetime, timezone


def parse_checkov(filepath):
    """Parse Checkov JSON results."""
    try:
        with open(filepath) as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {"passed": 0, "failed": 0, "failures": []}

    # Handle both single-framework and multi-framework output
    if isinstance(data, list):
        results = data[0].get("results", {}) if data else {}
    else:
        results = data.get("results", {})

    passed = results.get("passed_checks", [])
    failed = results.get("failed_checks", [])

    failures = []
    for check in failed:
        failures.append({
            "id": check.get("check_id", "unknown"),
            "name": check.get("check_name", "unknown"),
            "resource": check.get("resource", "unknown"),
            "file": check.get("file_path", "unknown"),
            "guide": check.get("guideline", ""),
        })

    return {
        "passed": len(passed),
        "failed": len(failed),
        "failures": failures,
    }


def parse_opa(filepath):
    """Parse OPA results text file."""
    findings = []
    try:
        with open(filepath) as f:
            for line in f:
                line = line.strip()
                if line.startswith("DENY:"):
                    findings.append(line.replace("DENY: ", ""))
    except FileNotFoundError:
        pass
    return findings


def generate_report(checkov_data, opa_findings):
    """Generate markdown compliance report."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    total_checks = checkov_data["passed"] + checkov_data["failed"] + len(opa_findings)
    total_pass = checkov_data["passed"]
    total_fail = checkov_data["failed"] + len(opa_findings)

    if total_checks > 0:
        pass_rate = (total_pass / total_checks) * 100
    else:
        pass_rate = 0

    lines = []
    lines.append("# NIST 800-53 Compliance Scan Report")
    lines.append(f"\n**Generated:** {now}")
    lines.append(f"**Pipeline:** Compliance-as-Code CI/CD")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"| Metric | Value |")
    lines.append(f"|--------|-------|")
    lines.append(f"| Total checks | {total_checks} |")
    lines.append(f"| Passed | {total_pass} |")
    lines.append(f"| Failed | {total_fail} |")
    lines.append(f"| Pass rate | {pass_rate:.1f}% |")
    lines.append("")

    # OPA findings
    lines.append("## OPA Custom Policy Results")
    lines.append("")
    if opa_findings:
        lines.append(f"**{len(opa_findings)} violation(s) found:**")
        lines.append("")
        for finding in opa_findings:
            # Extract the control ID from brackets
            control = ""
            if "[" in finding and "]" in finding:
                control = finding[finding.rindex("["):finding.rindex("]")+1]
            lines.append(f"- {control} {finding}")
        lines.append("")
    else:
        lines.append("All custom OPA policies passed.")
        lines.append("")

    # Checkov findings
    lines.append("## Checkov Static Analysis Results")
    lines.append("")
    lines.append(f"**Passed:** {checkov_data['passed']} | **Failed:** {checkov_data['failed']}")
    lines.append("")
    if checkov_data["failures"]:
        lines.append("| Check ID | Check Name | Resource | File |")
        lines.append("|----------|-----------|----------|------|")
        for f in checkov_data["failures"]:
            lines.append(f"| {f['id']} | {f['name']} | {f['resource']} | {f['file']} |")
        lines.append("")
    else:
        lines.append("All Checkov checks passed.")
        lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    checkov_path = sys.argv[1] if len(sys.argv) > 1 else "checkov-results.json"
    opa_path = sys.argv[2] if len(sys.argv) > 2 else "opa-results.txt"
    output_path = sys.argv[3] if len(sys.argv) > 3 else "compliance-report.md"

    checkov_data = parse_checkov(checkov_path)
    opa_findings = parse_opa(opa_path)
    report = generate_report(checkov_data, opa_findings)

    with open(output_path, "w") as f:
        f.write(report)

    print(f"Report generated: {output_path}")
    print(f"  Checkov: {checkov_data['passed']} passed, {checkov_data['failed']} failed")
    print(f"  OPA: {len(opa_findings)} finding(s)")
