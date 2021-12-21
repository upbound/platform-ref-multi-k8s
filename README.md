# Multi-cloud Kubernetes Reference Platform

This reference platform `Configuration` for multi-cloud Kubernetes is a starting point to build,
run, and operate your own internal cloud platform and offer a self-service console and API to your
internal teams.

It provides platform APIs to provision fully configured Kubernetes clusters across multiple cloud
providers, such as AWS, GCP, and Azure. Your app teams can use these platform APIs to self-service
provision their own Kubernetes clusters on demand when they need them, all while ensuring the
configuration and policy guardrails that you specified are also applied.

These platform APIs are composed using the following Crossplane providers:

* [Crossplane AWS Provider](https://doc.crds.dev/github.com/crossplane/provider-aws)
* [Crossplane GCP Provider](https://doc.crds.dev/github.com/crossplane/provider-gcp)
* [Crossplane Azure Provider](https://doc.crds.dev/github.com/crossplane/provider-azure)

App deployments can securely connect to the infrastructure they need using secrets distributed
directly to the app namespace.

## Quick Start

### Platform Ops/SRE: Run your own internal cloud platform

#### Create a free account in Upbound Cloud

1. Sign up for [Upbound Cloud](https://cloud.upbound.io/register).
1. Create an `Organization` for your teams.

#### Create a Platform instance in Upbound Cloud

1. Create a `Platform` in Upbound Cloud (e.g. dev, staging, or prod).
1. Connect `kubectl` to your `Platform` instance.

#### Install the Crossplane kubectl extension (for convenience)

```console
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
cp kubectl-crossplane /usr/local/bin
```

#### Install the Platform Configuration

```console
PLATFORM_CONFIG=registry.upbound.io/upbound/platform-ref-multi-k8s:v0.0.7

kubectl crossplane install configuration ${PLATFORM_CONFIG}
kubectl get pkg
```

#### AWS

Set up the AWS credentials and default AWS `ProviderConfig`:

```console
AWS_PROFILE=default && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > creds.conf
```

```console
kubectl create secret generic aws-creds -n crossplane-system --from-file=key=./creds.conf
kubectl apply -f examples/provider-default-aws.yaml
```

#### GCP

Set up your GCP account keyfile by following the instructions [here](https://crossplane.io/docs/v1.4/getting-started/install-configure.html#select-a-getting-started-configuration).

Ensure that the following roles are added to your service account (e.g. `sa-test`):

* `roles/compute.networkAdmin`
* `roles/container.admin`
* `roles/iam.serviceAccountUser`

Then create the secret using the given `creds.json` file:

```console
kubectl create secret generic gcp-credentials -n crossplane-system --from-file=credentials.json=./creds.json
```

Create the `ProviderConfig`, ensuring to set the `projectID` to your specific GCP project:

```console
kubectl apply -f examples/provider-default-gcp.yaml
```

#### Invite App Teams to you Organization in Upbound Cloud

1. Create a team `Workspace` in Upbound Cloud, named `team1`.
1. Enable self-service APIs in each `Workspace`.
1. Invite app team members and grant access to `Workspaces` in one or more
     `Platforms`.

### App Dev/Ops: Consume the infrastructure you need using kubectl

#### Join your Organization in Upbound Cloud

1. **Join** your [Upbound Cloud](https://cloud.upbound.io/register)
   `Organization`
1. Verify access to your team `Workspaces`

#### Provision a Network fabric in your team Workspace GUI console

1. Browse the available self-service APIs (XRDs) in your team `Workspace`
1. Provision a `Network` using the custom generated GUI for your
Platform `Configuration`
1. View status / details in your `Workspace` GUI console

#### Provision a Kubernetes cluster in your team Workspace GUI console

1. Browse the available self-service APIs (XRDs) in your team `Workspace`
1. Provision a `Cluster` using the custom generated GUI for your
Platform `Configuration`
1. View status / details in your `Workspace` GUI console

### Cleanup & Uninstall

#### Cleanup Resources

There are 2 options to delete resources created through the `Workspace` GUI:

* From the `Workspace` GUI using the ellipsis menu in the resource view.
* Using `kubectl delete -n team1 <claim-name>`.

Verify all underlying resources have been cleanly deleted:

```console
kubectl get managed
```

#### Uninstall Provider & Platform Configuration

```console
kubectl delete configurations.pkg.crossplane.io platform-ref-multi-k8s
kubectl delete providers.pkg.crossplane.io provider-aws
kubectl delete providers.pkg.crossplane.io provider-gcp
kubectl delete providers.pkg.crossplane.io provider-azure
kubectl delete providers.pkg.crossplane.io provider-helm
```

## APIs in this Configuration

* `Cluster` - provision a fully configured Kubernetes cluster in many different clouds
  * [definition.yaml](cluster/definition.yaml)
  * [composition-aws.yaml](cluster/composition-aws.yaml) includes (transitively):
    * `EKSCluster`
    * `NodeGroup`
    * `Role`
    * `RolePolicyAttachment`
    * `HelmReleases` for Prometheus and other cluster services.
  * [composition-gcp.yaml](cluster/composition-gcp.yaml) includes (transitively):
    * `GKECluster`
    * `NodePool`
    * `HelmReleases` for Prometheus and other cluster services.
* `Network` - fabric for a `Cluster` to securely connect the control plane, pods, and services
  * [definition.yaml](network/definition.yaml)
  * [composition-aws.yaml](network/composition-aws.yaml) includes:
    * `VPC`
    * `Subnet`
    * `InternetGateway`
    * `RouteTable`
    * `SecurityGroup`
  * [composition-gcp.yaml](network/composition-gcp.yaml) includes:
    * `Network`
    * `Subnetwork`

## Customize for your Organization

Create a `Repository` called `platform-ref-multi-k8s` in your Upbound Cloud `Organization`.

Set these to match your settings:

```console
UPBOUND_ORG=acme
UPBOUND_ACCOUNT_EMAIL=me@acme.io
REPO=platform-ref-multi-k8s
VERSION_TAG=v0.0.7
REGISTRY=registry.upbound.io
PLATFORM_CONFIG=${REGISTRY:+$REGISTRY/}${UPBOUND_ORG}/${REPO}:${VERSION_TAG}
```

Clone the GitHub repo.

```console
git clone https://github.com/upbound/platform-ref-multi-k8s.git
cd platform-ref-multi-k8s
```

Login to your container registry.

```console
docker login ${REGISTRY} -u ${UPBOUND_ACCOUNT_EMAIL}
```

Build package.

```console
kubectl crossplane build configuration --name package.xpkg --ignore "examples/*,hack/*,.github/*/*"
```

Push package to registry.

```console
kubectl crossplane push configuration ${PLATFORM_CONFIG} -f package.xpkg
```

Install package into an Upbound `Platform` instance.

```console
kubectl crossplane install configuration ${PLATFORM_CONFIG}
```

The cloud service primitives that can be used in a `Composition` today are
listed in the Crossplane provider docs:

* [Crossplane AWS Provider](https://doc.crds.dev/github.com/crossplane/provider-aws)
* [Crossplane GCP Provider](https://doc.crds.dev/github.com/crossplane/provider-gcp)
* [Crossplane Azure Provider](https://doc.crds.dev/github.com/crossplane/provider-azure)

To learn more see [Create a Configuration](https://crossplane.io/docs/v1.4/getting-started/create-configuration.html).

## Learn More

If you're interested in building your own reference platform for your company,
we'd love to hear from you and chat. You can setup some time with us at
info@upbound.io.

For Crossplane questions, drop by [slack.crossplane.io](https://slack.crossplane.io), and say hi!
