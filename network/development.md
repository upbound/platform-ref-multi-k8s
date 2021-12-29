# Local Dev Guide

These are in progress development iteration steps to run the following:

* a local `kind` cluster
* Crossplane as a helm chart from source
* `provider-aws`, `provider-gcp`, and `provider-helm` from published packages
* directly apply XRDs and Composition manifests with `kubectl`

## kind cluster and Crossplane

In the main `crossplane/crossplane` repo, run the following to bring up the cluster with the latest
locally built Crossplane:

```console
cluster/local/kind.sh up
cluster/local/kind.sh helm-install
```

Back in this repo, run the following to give Crossplane admin permissions, only for development purposes:

```console
kubectl apply -f hack/crossplane-cluster-admin-rolebinding.yaml
```

## `provider-aws` and `provider-helm`

```console
PROVIDER_AWS=registry.upbound.io/crossplane/provider-aws:v0.14.0
PROVIDER_GCP=registry.upbound.io/crossplane/provider-gcp:v0.13.0
PROVIDER_HELM=registry.upbound.io/crossplane/provider-helm:v0.3.7

kubectl crossplane install provider ${PROVIDER_AWS}
kubectl crossplane install provider ${PROVIDER_GCP}
kubectl crossplane install provider ${PROVIDER_HELM}
kubectl get pkg
```

## Multicloud Kubernetes reference platform

Create all the XRDs and Compositions:

```console
for f in $(find . -name 'definition.yaml'); do kubectl apply -f $f; done
for f in $(find . -name 'composition*.yaml'); do kubectl apply -f $f; done
```

### AWS

Set up the AWS credentials and default AWS `ProviderConfig`:

```console
AWS_PROFILE=default && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > creds.conf
```

```console
kubectl create secret generic aws-creds -n crossplane-system --from-file=key=./creds.conf
kubectl apply -f examples/provider-default-aws.yaml
```

### GCP

Set up your GCP account keyfile by following the instructions on:
https://crossplane.io/docs/v0.14/getting-started/install-configure.html#select-provider

Then create the secret using the given `creds.json` file:

```console
kubectl create secret generic gcp-creds -n crossplane-system --from-file=key=./creds.json
```

Create the `ProviderConfig`, ensuring to set the `projectID` to your specific GCP project:

```console
kubectl apply -f examples/provider-default-gcp.yaml
```

## Create Resources

Now that the providers, XRDs, and credentials are configured, we can create instances of the resources offered by our infrastructure API.

First, choose *only one** of these env vars to select a provider:

```console
PROVIDER=aws
PROVIDER=gcp
```

Now, create a network claim that will use the composition for your provider:

```console
kubectl apply -f examples/network-${PROVIDER}.yaml
```

After all the network resources are ready, you can then create a cluster for your provider:

```console
kubectl apply -f examples/cluster-${PROVIDER}.yaml
```

## Clean up

```console
kubectl delete -f examples/cluster-${PROVIDER}.yaml
# wait for all cluster resources to be cleaned up
kubectl delete -f examples/network-${PROVIDER}.yaml

for f in $(find . -name 'composition*.yaml'); do kubectl delete -f $f; done
for f in $(find . -name 'definition.yaml'); do kubectl delete -f $f; done

kubectl delete -f examples/provider-default-${PROVIDER}.yaml
kubectl -n crossplane-system delete secret ${PROVIDER}-creds
rm -fr creds.*

cluster/local/kind.sh clean
```
