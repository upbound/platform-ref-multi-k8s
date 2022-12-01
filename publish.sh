. ./vars.sh

echo "publish the package"
kubectl crossplane push configuration ${CONFIGPKG} -f target/${PACKAGE}
