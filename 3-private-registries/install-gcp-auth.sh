helm upgrade --install kyverno kyverno \
  --repo https://kyverno.github.io/kyverno/ \
  --namespace kyverno --create-namespace \
  --set replicaCount=1 \
  --wait

PRINT_GCP_AUTH_SECRET_SCRIPT='
registry_hosts=(
	"gcr.io"
	"us.gcr.io"
	"eu.gcr.io"
	"asia.gcr.io"
	"marketplace.gcr.io"
  "asia-docker.pkg.dev"
	"asia-east1-docker.pkg.dev"
	"asia-east2-docker.pkg.dev"
	"asia-northeast1-docker.pkg.dev"
	"asia-northeast2-docker.pkg.dev"
	"asia-northeast3-docker.pkg.dev"
	"asia-south1-docker.pkg.dev"
	"asia-south2-docker.pkg.dev"
	"asia-southeast1-docker.pkg.dev"
	"asia-southeast2-docker.pkg.dev"
	"australia-southeast1-docker.pkg.dev"
	"australia-southeast2-docker.pkg.dev"
	"europe-docker.pkg.dev"
	"europe-central2-docker.pkg.dev"
	"europe-north1-docker.pkg.dev"
	"europe-southwest1-docker.pkg.dev"
	"europe-west1-docker.pkg.dev"
	"europe-west2-docker.pkg.dev"
	"europe-west3-docker.pkg.dev"
	"europe-west4-docker.pkg.dev"
	"europe-west6-docker.pkg.dev"
	"europe-west8-docker.pkg.dev"
	"europe-west9-docker.pkg.dev"
	"europe-west12-docker.pkg.dev"
	"me-west1-docker.pkg.dev"
	"northamerica-northeast1-docker.pkg.dev"
	"northamerica-northeast2-docker.pkg.dev"
	"southamerica-east1-docker.pkg.dev"
	"southamerica-west1-docker.pkg.dev"
	"us-docker.pkg.dev"
	"us-central1-docker.pkg.dev"
	"us-east1-docker.pkg.dev"
	"us-east4-docker.pkg.dev"
	"us-east5-docker.pkg.dev"
	"us-south1-docker.pkg.dev"
	"us-west1-docker.pkg.dev"
	"us-west2-docker.pkg.dev"
	"us-west3-docker.pkg.dev"
	"us-west4-docker.pkg.dev"
)

token="$(gcloud auth print-access-token)"

dockercfg="{\"auths\": {"
for host in "${registry_hosts[@]}"; do
  dockercfg+="\"https://${host}\":{\"username\":\"oauth2accesstoken\",\"password\":\"$token\",\"email\":\"none\"},"
done
dockercfg="${dockercfg%,}"
dockercfg+="}}"

cat <<EOF
kind: Secret
apiVersion: v1
metadata:
  name: gcp-auth
  namespace: gcp-auth
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: $(echo "$dockercfg" | base64 | tr -d "\\n")
EOF
'

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: gcp-auth
---
$(eval "$PRINT_GCP_AUTH_SECRET_SCRIPT")
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
$(echo "$PRINT_GCP_AUTH_SECRET_SCRIPT" | sed 's/^/    /')
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
              /scripts/print-gcp-auth-secret.sh | kubectl apply -f -
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
