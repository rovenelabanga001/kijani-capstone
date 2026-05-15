# Capstone Scope Document
**Project:** KijaniKiosk Production-Approaching Deployment Pipeline  
**Track:** Track A — Infrastructure First  
**Author:** Rovenel Abanga 
**Date:** 2026-05-15

---

## Problem Statement

KijaniKiosk currently operates a single deployment environment. Every change to kk-payments is applied directly to the only running environment using manual kubectl commands, with no automated validation before or after the deployment. There is no staging environment to catch regressions before they affect live traffic, no pipeline that enforces a smoke test before a production approval gate, no environment-specific configuration separating staging database connections from production, and no alerting that fires when kk-payments health degrades. At 50,000 transactions per hour, a misconfiguration that reaches the live environment without automated detection has no recovery path faster than a human noticing, diagnosing, and rolling back manually. The capstone closes this gap by building the staging environment, the automated pipeline, the environment-specific configuration, and the health alerting that make the system safe to operate without constant human supervision.

---

## Track

**Track A — Infrastructure First**

---

## What I Will Build

- **kijani-staging namespace:** A Kubernetes namespace provisioned by Terraform and configured by Ansible, isolated from the default namespace, with its own resource quota and environment-specific ConfigMaps pointing to staging infrastructure.

- **Jenkins pipeline:** A pipeline that deploys kk-payments to kijani-staging automatically on every merge to main, runs a smoke test against the staging health endpoint, and only opens the production approval gate after the smoke test passes with exit 0.

- **Environment-specific ConfigMaps:** Two ConfigMap manifests — one for staging, one for production — using the same Deployment manifest for both environments, with DB_HOST, LOG_LEVEL, and NODE_ENV differing between them.

- **Prometheus alert rule:** At least one alert rule committed to the repository that fires when kk-payments pod restart count exceeds two within a five-minute window, representing a crash loop that requires immediate attention.

- **Serverless receipt chain integration:** kk-payments in the staging environment configured to write receipt events to the kk-payments-receipts-staging bucket, with the receipt chain triggered and verified by a test payment through the staging deployment.

---

## What Is Out of Scope

- **TLS termination on the Ingress:** Configuring cert-manager and a ClusterIssuer for HTTPS requires a publicly routable domain and a certificate authority integration. The capstone runs on a local Minikube cluster where neither is available. TLS is documented as a production gap but not implemented.

- **Horizontal Pod Autoscaler:** The HPA requires a stable metrics-server and reliable CPU load generation to demonstrate meaningfully. On a single-node Minikube cluster, load generation is not reproducible enough to produce a clean demonstration. Manual scaling to six replicas (demonstrated in Week 9) covers the scaling requirement for this project.

- **Production serverless deployment:** The serverless receipt chain integration is demonstrated in the staging environment only. A real cloud deployment requires AWS credentials, billing configuration, and a publicly routable endpoint — none of which are available in the local lab environment.

---

## Success Criteria

1. `kubectl get all -n kijani-staging` returns both kk-payments Deployments and Services in Running/Ready state after a fresh `terraform apply` and `ansible-playbook` run, with no manual kubectl commands required.

2. A merge to the main branch triggers the Jenkins pipeline automatically, the smoke test against `http://kijani-staging.local/payments/health` returns HTTP 200, and the production approval gate appears in the Jenkins UI — all without human intervention between the merge and the gate.

3. The Prometheus alert rule transitions from `inactive` to `firing` within five minutes of a simulated kk-payments crash loop (introduced by setting an invalid image tag), and returns to `inactive` within five minutes of the rollback completing.

---

## Architecture diagram

![Architecture diagram](architecture.png)