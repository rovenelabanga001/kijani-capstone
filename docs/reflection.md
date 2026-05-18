# Capstone Reflection — kijani-capstone
**Track:** Track A — Infrastructure First  
**Date:** 2026-05-16

---

## What did I get wrong?

The ResourceQuota in Terraform was set with `limits.cpu: 1000m` — enough for two
Pods at 500m each but not three. The Deployment specified `replicas: 3` and
`limits.cpu: 500m` per container, which means three replicas require 1500m of CPU
limit headroom. The quota blocked the third Pod from starting and the Deployment
sat at 2/3 replicas with a `FailedCreate` condition and no obvious error message
in the rollout output.

The correct approach would have been to calculate the quota headroom before writing
either file. The formula is simple: `quota.limits.cpu` must be greater than
`replicas × container.limits.cpu`. Writing the Deployment and the quota
independently without checking their relationship against each other is the mistake.
In a real team, this would be caught by a reviewer comparing the two files, but in
a solo project there was no second set of eyes on the arithmetic.

The fix was a Terraform `plan` and `apply` to increase `limits.cpu` to `2000m`,
followed by `kubectl rollout restart` to force the Deployment controller to retry.
The patch worked but the correct sequence would have been: define replica count →
define per-Pod resource limits → set quota to replica count × limit plus 20%
headroom → apply in that order.

---

## What is the most important thing I learned?

The most important thing learned was the difference between a Kubernetes resource
being created and a Kubernetes resource being discovered — specifically how the
`release: prometheus` label on a PrometheusRule determines whether the
kube-prometheus-stack operator picks it up.


The label `release: prometheus` is the selector the Helm-installed operator uses to
find PrometheusRule objects. Without it, the object is valid Kubernetes YAML and
applies cleanly, but is invisible to Prometheus. What changed in thinking: YAML
being accepted by the API server is not the same as YAML being acted upon by the
operator watching for it. Every Kubernetes resource that is consumed by a controller
has a selector, and the selector is the contract between the resource and the
controller. Missing the selector produces a silent no-op, not an error.

---

## What would I do differently on a second pass?

Three specific changes:

**First:** Replace the Ansible playbook credential injection with a Kubernetes
External Secrets Operator integration pointing at a local Vault instance. The
current approach requires a human to copy `playbook.yml.example`, fill in real
values, and run the playbook manually. This is a documented gap in the README but
it means the setup is not fully reproducible from a clean checkout without human
knowledge of the credential values. External Secrets Operator would read from Vault
at apply time, removing the manual step entirely and making the setup commands in
the README genuinely runnable without prior knowledge.

**Second:** Add a fourth Prometheus alert rule targeting
`kube_pod_container_status_waiting_reason{reason="ImagePullBackOff"}`. The
`KkPaymentsPodCrashLooping` rule was validated during the capstone but the
deliberate fault test used an invalid image tag, which produces `ImagePullBackOff`
rather than a restart loop. The crash loop rule never fired because the container
never started. The most common deployment failure mode in this project was
`ImagePullBackOff` and there is no alert for it. A second pass would add this rule
and validate it specifically with an invalid image tag test.

**Third:** Remove the `diagnose-failure.sh` script from the pipeline and replace it
with a Jenkins shared library step. The current script is a standalone bash file
that runs with `ANTHROPIC_API_KEY` injected as an environment variable. Moving it
to a shared library would make it testable, versionable independently of the
capstone repository, and reusable across other pipelines. The governance log Entry
003 documents that the script was simplified because it was too complex to govern
as a bash file — a shared library step would solve that problem at the right layer
rather than by reducing complexity.