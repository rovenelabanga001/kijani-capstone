# Peer Feedback Log — kijani-capstone

**Review type:** Self-review 
**Date:** 2026-05-16  

---

## Entry 001

**Issue:** The README Setup section Step 4 says "copy the example playbook and fill in real credentials" but does not name the specific fields that need to be changed. A reviewer following the README would open `playbook.yml` and not know which values to replace without reading the entire file.  
**Severity:** Blocks setup  
**Resolution:** Added a specific list of the three fields to replace (`DB_PASSWORD`, `STRIPE_API_KEY`, `JWT_SECRET`) directly in the README Setup step, with a note that placeholder values are acceptable for a local lab environment.  
**Evidence:** Commit `fix: clarify ansible playbook credential fields in README setup step`

---

## Entry 002

**Issue:** The verification command in the README for checking Prometheus alert state requires the port-forward to already be running in the background. If the reviewer runs the commands in order on a fresh terminal, the port-forward is not running and the curl returns `connection refused`. The README does not mention this dependency.  
**Severity:** Breaks functionality  
**Resolution:** Updated the verification section to include the port-forward command before the curl command, with a note that it runs in the background and can be stopped with `kill %1` after verification.  
**Evidence:** Commit `fix: add port-forward step to prometheus verification commands in README`

---

## Entry 003

**Issue:** The `monitoring/alerts.yml` file has no comment explaining that the `release: prometheus` label is required for the kube-prometheus-stack operator to discover the PrometheusRule. Without this label, the rules are silently ignored. A new engineer applying the file would see it created successfully but the alerts would never appear in Prometheus.  
**Severity:** Unclear documentation  
**Resolution:** Added a comment block at the top of `monitoring/alerts.yml` explaining the label requirement and how to verify the rules were discovered using the Prometheus rules API.  
**Evidence:** Commit `docs: add label requirement comment to prometheus alerts manifest`

---


## GitHub Issues

| Issue | Title | Status | Closing commit |
|-------|-------|--------|----------------|
| #1 | README setup step 4 missing specific credential field names | Closed | `fix: clarify ansible playbook credential fields in README setup step` |
| #2 | Prometheus verification fails on fresh terminal — missing port-forward step | Closed | `fix: add port-forward step to prometheus verification commands in README` |
| #3 | alerts.yml missing label requirement comment | Closed | `docs: add label requirement comment to prometheus alerts manifest` |