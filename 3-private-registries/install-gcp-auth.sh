helm upgrade --install kyverno kyverno \
  --repo https://kyverno.github.io/kyverno/ \
  --namespace kyverno --create-namespace \
  --set replicaCount=1 \
  --wait

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: gcp-auth
---
$($(dirname "$0")/print-gcp-auth-secret.sh "gcp-auth")
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: sync-secrets
spec:
  generateExistingOnPolicyUpdate: true
  rules:
    - name: sync-image-pull-secret
      match:
        any:
          - resources:
              kinds:
                - Namespace
      generate:
        apiVersion: v1
        kind: Secret
        name: gcp-auth
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        clone:
          namespace: gcp-auth
          name: gcp-auth
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-imagepullsecrets
spec:
  rules:
    - name: add-imagepullsecret
      match:
        any:
          - resources:
              kinds:
                - Pod
      mutate:
        patchStrategicMerge:
          spec:
            imagePullSecrets:
              - name: gcp-auth
EOF

# Token Refresh Mechanism
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gcp-auth
  namespace: gcp-auth
automountServiceAccountToken: true
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gcp-auth-secret-mutation
  namespace: gcp-auth
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: gcp-auth-secret-mutation-binding
  namespace: gcp-auth
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: gcp-auth-secret-mutation
subjects:
- kind: ServiceAccount
  name: gcp-auth
  namespace: gcp-auth
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: gcp-auth-scripts
  namespace: gcp-auth
data:
  print-gcp-auth-secret.sh: |
$(cat $(dirname "$0")/print-gcp-auth-secret.sh | sed 's/^/    /')
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gcp-auth
  namespace: gcp-auth
spec:
  selector:
    matchLabels:
      app: gcp-auth
  template:
    metadata:
      labels:
        app: gcp-auth
    spec:
      serviceAccountName: gcp-auth
      containers:
        - name: gcp-auth
          image: gcr.io/google.com/cloudsdktool/google-cloud-cli
          imagePullPolicy: IfNotPresent
          volumeMounts:
          - name: gcloud-config
            mountPath: /root/.config/gcloud
          - name: scripts
            mountPath: /scripts
          command:
            - /bin/bash
            - -c
            - |
              while true; do
              echo "Updating gcp-auth secret..."
              /scripts/print-gcp-auth-secret.sh gcp-auth | kubectl apply -f -
              sleep 300
              done
      volumes:
      - name: gcloud-config
        hostPath:
          path: "$HOME/.config/gcloud"
      - name: scripts
        configMap:
          name: gcp-auth-scripts
          defaultMode: 0777
EOF
