. ./vars.sh

kubectl delete ns ${TESTNS} 2>/dev/null

# delete all compositions
for i in $(kubectl get composition -o name); do kubectl delete $i; done

# delete all xrds
for i in $(kubectl get xrd -o name); do kubectl delete $i; done

# delete all configurations
for i in $(kubectl get configuration -o name); do kubectl delete $i; done

# delete all providers
for i in $(kubectl get providers -o name); do kubectl delete $i; done

# delete all providerconfigs
kubectl delete providerconfig.kubernetes.crossplane.io/kubernetes-provider

# cleanup previous builds
rm -R target 2>/dev/null

