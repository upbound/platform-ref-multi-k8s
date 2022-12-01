. ./vars.sh

echo "prepare for testing..."
kubectl create ns ${TESTNS} 2>/dev/null
echo "check all crossplane packages are ready"
for i in $(kubectl get pkg -o name); do kubectl wait --for=condition=Healthy $i; done

echo "check xrds are available"
CRD=grapi && echo "wait for ${CRD} to be deployed:" && until kubectl explain ${CRD} >/dev/null 2>&1; do echo -n .; sleep 1; done && echo "${CRD} deployed"
CRD=compositegrappleapis && echo "wait for ${CRD} to be deployed:" && until kubectl explain ${CRD} >/dev/null 2>&1; do echo -n .; sleep 1; done && echo "${CRD} deployed"
CRD=composition/grapi.gsf.grpl.io && echo "wait for ${CRD} to be deployed:" && until kubectl get ${CRD} >/dev/null 2>&1; do echo -n .; sleep 1; done && echo "${CRD} deployed"


echo "check composition is available"

echo "deploy the test case"
cat <<EOF | kubectl apply -n ${TESTNS} -f -
apiVersion: gsf.grpl.io/v1alpha1
kind: GrappleApi
metadata:
  name: mygrapi
spec:
  id: mygrapiid
EOF

echo "display status of packages and XRDs"
kubectl get pkg
kubectl get xrd
echo
echo "----"
echo
kubectl get composition
echo
echo "----"
echo
kubectl get composite
kubectl get claim -n ${TESTNS}
echo
echo "----"
echo
echo "display status of test case"
kubectl get grapi,all -n ${TESTNS}
