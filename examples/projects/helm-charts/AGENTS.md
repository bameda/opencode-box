# Helm charts

- After changing a chart, validate it in this order and fix every error
  before going on:
  1. `helm lint <chart>`
  2. `helm template test <chart> | kubeconform -strict -summary`
  3. `ct lint --charts <chart>`
  4. `helm install` it in a new namespace of the simulated cluster
     (`$KUBECONFIG` already points to it), check the resources with
     `kubectl get`, then `helm uninstall` it.
- The cluster is simulated by kwok: no container ever runs. Do not use
  `helm install --wait` or `helm test`, and do not try to debug Pods,
  logs or networking there. Say what needs testing on a real cluster.
- Every change to a chart bumps its `version` in `Chart.yaml`, and
  `appVersion` when the application changes. Regenerate its README with
  `helm-docs` when values change.
- Push packaged charts only to the local registry (`oci://$OCI_REGISTRY`,
  with `--plain-http`). Never push anywhere else.
