. ./vars.sh

# cleanup previous builds
rm -R target 2>/dev/null
mkdir -p target 2>/dev/null

# build the crossplane package
kubectl crossplane build configuration --name=${PACKAGE} --ignore=".gitpod.yml,examples/*,hack/*,.github/*/*,target/*,*.sh,cluster/*,cluster/*/*,network/*"
# kubectl crossplane build configuration --name ${PACKAGE} --ignore ".gitpod.yml,examples/*,hack/*,.github/*/*,target/*,*.sh,cluster/*,cluster/*/*,grapi/*"

mv ${PACKAGE} ./target/
