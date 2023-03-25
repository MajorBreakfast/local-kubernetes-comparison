namespace=${1:-"default"}

registry_hosts=(
  "gcr.io"
  "us.gcr.io"
  "eu.gcr.io"
  "asia.gcr.io"
  $(gcloud artifacts locations list --format 'value(name)')
)

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
  namespace: $namespace
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: $(echo "$dockercfg" | base64 | tr -d \\n)
EOF
