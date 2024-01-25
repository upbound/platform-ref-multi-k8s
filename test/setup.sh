#!/usr/bin/env bash
set -aeuo pipefail

UPTEST_GCP_PROJECT=${UPTEST_GCP_PROJECT:-official-provider-testing}

echo "Running setup.sh"
echo "Waiting until all configuration packages are healthy/installed..."
"${KUBECTL}" wait configuration.pkg --all --for=condition=Healthy --timeout 5m
"${KUBECTL}" wait configuration.pkg --all --for=condition=Installed --timeout 5m
"${KUBECTL}" wait configurationrevisions.pkg --all --for=condition=Healthy --timeout 5m

echo "Waiting until all installed provider packages are healthy..."
"${KUBECTL}" wait provider.pkg --all --for condition=Healthy --timeout 5m

echo "Waiting for all pods to come online..."
"${KUBECTL}" -n upbound-system wait --for=condition=Available deployment --all --timeout=5m

echo "Waiting for all XRDs to be established..."
"${KUBECTL}" wait xrd --all --for condition=Established

if [[ -n "${UPTEST_CLOUD_CREDENTIALS:-}" ]]; then
  # UPTEST_CLOUD_CREDENTIALS may contain more than one cloud credentials that we expect to be provided
  # in a single GitHub secret. We expect them provided as key=value pairs separated by newlines. Currently we expect
  # two AWS IAM user credentials to be provided. For example:
  # AWS='[default]
  # aws_access_key_id = REDACTED
  # aws_secret_access_key = REDACTED'
  # AZURE='{
  # "clientId": "REDACTED",
  # "clientSecret": "REDACTED",
  # "subscriptionId": "REDACTED",
  # "tenantId": "REDACTED",
  # "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  # "resourceManagerEndpointUrl": "https://management.azure.com/",
  # "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  # "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  # "galleryEndpointUrl": "https://gallery.azure.com/",
  # "managementEndpointUrl": "https://management.core.windows.net/"
  # }'
  # GCP='
  # {
  # "type": "service_account",
  # "project_id": "caramel-goat-354919",
  # "private_key_id": "e97e40a4a27661f12345678f4bd92139324dbf46",
  # "private_key": "-----BEGIN PRIVATE KEY-----\n===\n-----END PRIVATE KEY-----\n",
  # "client_email": "my-sa-313@caramel-goat-354919.iam.gserviceaccount.com",
  # "client_id": "103735491955093092925",
  # "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  # "token_uri": "https://oauth2.googleapis.com/token",
  # "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  # "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/my-sa-313%40caramel-goat-354919.iam.gserviceaccount.com"
  # }'
  eval "${UPTEST_CLOUD_CREDENTIALS}"

  if [[ -n "${AWS:-}" ]]; then
    echo "Creating the AWS default cloud credentials secret..."
    ${KUBECTL} -n upbound-system create secret generic aws-creds --from-literal=credentials="${AWS}" --dry-run=client -o yaml | ${KUBECTL} apply -f -

    echo "Creating the AWS default provider config..."
    cat <<EOF | ${KUBECTL} apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      name: aws-creds
      namespace: upbound-system
      key: credentials
EOF
  fi

  if [[ -n "${GCP:-}" ]]; then
    echo "Creating the GCP default cloud credentials secret..."
    ${KUBECTL} -n upbound-system create secret generic gcp-creds --from-literal=credentials="${GCP}" --dry-run=client -o yaml | ${KUBECTL} apply -f -

    echo "Creating the GCP default provider config..."
    cat <<EOF | ${KUBECTL} apply -f -
apiVersion: gcp.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    secretRef:
      key: credentials
      name: gcp-creds
      namespace: upbound-system
    source: Secret
  projectID: ${UPTEST_GCP_PROJECT}
EOF
  fi

  if [[ -n "${AZURE:-}" ]]; then
    echo "Creating the AZURE default cloud credentials secret..."
    ${KUBECTL} -n upbound-system create secret generic azure-creds --from-literal=credentials="${AZURE}" --dry-run=client -o yaml | ${KUBECTL} apply -f -

    echo "Creating the Azure default provider config..."
    cat <<EOF | ${KUBECTL} apply -f -
apiVersion: azure.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      name: azure-creds
      namespace: upbound-system
      key: credentials
EOF
  fi
fi
