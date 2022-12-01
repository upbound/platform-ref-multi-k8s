. ./vars.sh

echo "install crossplane"
kubectl create namespace ${CPSYS} 2>/dev/null
helm repo add crossplane-stable https://charts.crossplane.io/stable 2>/dev/null
helm repo update

helm upgrade --install crossplane --namespace ${CPSYS} crossplane-stable/crossplane --wait

CRD=provider && echo "wait for ${CRD} to be deployed:" && until kubectl explain ${CRD} >/dev/null 2>&1; do echo -n .; sleep 1; done && echo "${CRD} deployed"

echo "install the crossplane configuration"
kubectl crossplane install configuration ${CONFIGPKG}

echo "wait for all crossplane packages to be healthy"
for i in $(kubectl get pkg -o name); do kubectl wait --for=condition=Healthy $i; done

# echo "deploy the provider config"
# cat <<EOF | kubectl apply -n ${CPSYS} -f -
# apiVersion: kubernetes.crossplane.io/v1alpha1
# kind: ProviderConfig
# metadata:
#   name: kubernetes-provider
# spec:
#   credentials:
#     source: InjectedIdentity
# EOF

# ensure that crossplane user has permissions:
# k edit clusterrole crossplane
# cat hack/crossplane-cluster-admin-rolebinding.yaml

cat <<EOF | kubectl apply -n ${CPSYS} -f -
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: kubernetes-provider
spec:
  credentials:
    source: InjectedIdentity
EOF

# ensure that crossplane user has permissions:
# k edit clusterrole crossplane
# cat hack/crossplane-cluster-admin-rolebinding.yaml

# ensure that crossplane kubernetes user has permissions:
SA=$(kubectl -n ${CPSYS} get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|crossplane-system:|g' | sed "s|crossplane-system|${CPSYS}|g")
kubectl create clusterrolebinding crssplane-provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}" 
# temporary - need for a better solution
