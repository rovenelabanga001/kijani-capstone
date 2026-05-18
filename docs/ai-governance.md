# AI Governance Log — kijani-capstone

This log records every use of AI tooling during the capstone project.
Each entry follows the eight-field format defined in the Week 10 capstone guide.

---

## Entry 001 — Kubernetes manifests for kk-payments staging deployment

**Date:** 2026-05-15  
**Task:** Generate initial Kubernetes Deployment, Service, and Ingress manifests for the kijani-staging namespace  
**Tool:** Claude Sonnet (claude.ai chat)  
**What the AI produced:** A complete Deployment manifest with readiness and liveness probes, resource requests and limits, envFrom referencing both ConfigMap and Secret, and a ClusterIP Service. Also produced a NodePort Ingress with a single `/payments` path rule.  
**What it got wrong:** The Ingress used `pathType: Prefix` with `rewrite-target: /` which stripped the full path instead of preserving the suffix. A request to `/payments/health` was forwarded as `/` to the backend, returning `Not found`. The fix required changing to `pathType: ImplementationSpecific` with path `/payments(/|$)(.*)` and `rewrite-target: /$2` to capture and forward the path suffix correctly.  
**Specific change the reviewer made:** Replaced the path and rewrite-target annotation in `k8s/kijani-ingress.yaml`. Verified the fix by running `curl -v http://kijani-staging.local/payments/health` and confirming the backend received `/health` not `/`.  
**Governance checklist item referenced:** Control 3 — Human review of AI output before deployment. The manifest was applied to a non-production namespace first and the routing was verified with curl before the fix was committed.  
**Outcome:** Manifest committed after fix. The AI output provided a correct structural starting point but required a non-trivial routing correction that would have caused a silent failure in production.

---

## Entry 002 — Prometheus alert rules for kk-payments health signals

**Date:** 2026-05-15  
**Task:** Generate PrometheusRule manifest with alert rules targeting kk-payments crash loops, pod readiness, and availability  
**Tool:** Claude Sonnet (claude.ai chat)  
**What the AI produced:** Three alert rules — `KkPaymentsPodCrashLooping` using `increase(kube_pod_container_status_restarts_total[5m]) > 2`, `KkPaymentsPodsNotReady` comparing ready replicas to desired replicas, and `KkPaymentsDeploymentUnavailable` firing when available replicas equals zero.  
**What it got wrong:** The `KkPaymentsPodCrashLooping` rule did not fire during the deliberate fault injection test. The fault used an invalid image tag which causes `ImagePullBackOff` — the container never starts, so the restart counter never increments. The rule is technically correct for actual crash loops but does not cover the most common deployment failure mode (image pull failure). A separate rule targeting `kube_pod_container_status_waiting_reason{reason="ImagePullBackOff"}` would be needed to cover this case.  
**Specific change the reviewer made:** Added a comment to `monitoring/alerts.yml` documenting the ImagePullBackOff gap. Did not add a fourth rule within the project timeline — documented as a known limitation. The `KkPaymentsPodsNotReady` rule correctly fired during the test, confirming partial coverage.  
**Governance checklist item referenced:** Control 5 — Documented limitations of AI-generated operational configuration. The gap between what the rule claims to detect and what it actually detects in the ImagePullBackOff scenario is recorded here rather than left as an invisible assumption.  
**Outcome:** Two of three rules validated by live test. The crash loop rule requires a real crash loop (not an image pull failure) to fire. This distinction is documented in the known limitations section of the README.

---
