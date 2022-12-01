. ./vars.sh

kubectl delete -n grpl-test GrappleApi mygrapi 2>/dev/null
kubectl delete objects -l crossplane.io/claim-name=mygrapi 2>/dev/null
kubectl delete crd customresourcedefinition.apiextensions.k8s.io/objects.kubernetes.crossplane.io 2>/dev/null

kubectl delete ns ${TESTNS} 2>/dev/null

echo "delete all compositions"
for i in $(kubectl get composition -o name); do kubectl delete $i 2>/dev/null; done

echo "delete all xrds"
for i in $(kubectl get xrd -o name); do kubectl delete $i 2>/dev/null; done

echo "delete all configurations"
for i in $(kubectl get configuration -o name); do kubectl delete $i 2>/dev/null; done

echo "delete all providers"
for i in $(kubectl get providers -o name); do kubectl delete $i 2>/dev/null; done

echo "delete all providerconfigs"
kubectl delete providerconfig.kubernetes.crossplane.io/kubernetes-provider 2>/dev/null

echo "cleanup previous builds"
rm -R target 2>/dev/null

echo "uninstall crossplane"
helm uninstall --namespace ${CPSYS} crossplane --wait 2>/dev/null
kubectl delete namespace ${CPSYS} 2>/dev/null


