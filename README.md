# Multi-cloud Kubernetes Reference Platform

This repository contains a reference Multi-cloud Kubernetes Platform
Configuration for [Crossplane](https://crossplane.io). It's a great
starting point for building internal cloud platforms with AWS and
offering a self-service API to your internal development teams.

This platform offers APIs for setting up fully configured Kubernetes
clusters across multiple cloud providers, such as AWS, GCP, and Azure.
Your app teams can use these platform APIs to self-service provision
their own Kubernetes clusters on demand when they need them, all while
ensuring the configuration and policy guardrails that you specified are
also applied.

## Overview

This reference platform outlines a specialized API for generating an Cluster
([XCluster](apis/definition.yaml)) that incorporates XRs from the specified configurations:

* [upbound-configuration-aws-eks](https://github.com/upbound/configuration-aws-eks)
* [upbound-configuration-aws-network](https://github.com/upbound/configuration-aws-network)
* [upbound-configuration-gcp-gke](https://github.com/upbound/configuration-gcp-gke)
* [upbound-configuration-gcp-network](https://github.com/upbound/configuration-gcp-network)
* [upbound-configuration-azure-aks](https://github.com/upbound/configuration-azure-aks)
* [upbound-configuration-azure-network](https://github.com/upbound/configuration-azure-network)
* [upbound-configuration-gitops-flux](https://github.com/upbound/configuration-gitops-flux)
* [upbound-configuration-observability-oss](https://github.com/upbound/configuration-observability-oss)

```mermaid
graph LR;
    MyApp(my-cluster)---MyCluster(XRC: my-cluster);
    MyCluster---XRD1(XRD: XCluster);
		subgraph Configuration:upbound/platform-ref-multi-k8s;
	    XRD1---Composition(XEKS*, XAKS*, XGCP*, XNetwork, XFlux, XOss);
		end
		subgraph Provider:upbound/provider-aws
	    Composition---aws1.MRs(MRs: IAM Role, VPC, Subnet);
	    Composition---aws2.MRs(MRs: EKS Cluster, ClusterAuth, NodeGroup);
		end
		subgraph Provider:upbound/provider-azure
	    Composition---azure1.MRs(MRs: ResourceGroup, Subnet, VirtualNetwork);
	    Composition---azure2.MRs(MRs: KubernetesCluster);
		end
		subgraph Provider:upbound/provider-gcp
	    Composition---gcp1.MRs(MRs: ProjectIAMMember, ServiceAccountKey);
	    Composition---gcp2.MRs(MRs: Cluster, NodePool);
		end

style MyApp color:#000,fill:#e6e6e6,stroke:#000,stroke-width:2px
style MyCluster color:#000,fill:#D68A82,stroke:#000,stroke-width:2px
style Provider:upbound/provider-aws fill:#81CABB,opacity:0.3
style Provider:upbound/provider-azure fill:#81CABB,opacity:0.3
style Provider:upbound/provider-gcp fill:#81CABB,opacity:0.3
style XRD1 color:#000,fill:#f1d16d,stroke:#000,stroke-width:2px,stroke-dasharray: 5 5
style Composition color:#000,fill:#f1d16d,stroke:#000,stroke-width:2px
style aws1.MRs color:#000,fill:#81CABB,stroke:#000,stroke-width:2px
style aws2.MRs color:#000,fill:#81CABB,stroke:#000,stroke-width:2px
style azure1.MRs color:#000,fill:#81CABB,stroke:#000,stroke-width:2px
style azure2.MRs color:#000,fill:#81CABB,stroke:#000,stroke-width:2px
style gcp1.MRs color:#000,fill:#81CABB,stroke:#000,stroke-width:2px
style gcp2.MRs color:#000,fill:#81CABB,stroke:#000,stroke-width:2px
```

Learn more about Composite Resources in the [Crossplane Docs](https://docs.crossplane.io/latest/concepts/compositions/).

## Quickstart

### Prerequisites

Before we can install the reference platform we should install the `up` CLI.
This is a utility that makes following this quickstart guide easier. Everything
described here can also be done in a declarative approach - which we highly
recommend for any production type use-case.
<!-- TODO enhance this guide: Getting ready for Gitops -->

To install `up` run this install script:
```console
curl -sL https://cli.upbound.io | sh
```
See [up docs](https://docs.upbound.io/cli/) for more install options.

We need a running Crossplane control plane to install our instance. We are
using [Universal Crossplane (UXP)](https://github.com/upbound/universal-crossplane).
Ensure that your kubectl context points to the correct Kubernetes cluster or
create a new [kind](https://kind.sigs.k8s.io) cluster:

```console
kind create cluster
```

Finally install UXP into the `upbound-system` namespace:

```console
up uxp install
```

You can validate the install by inspecting all installed components:

```console
kubectl get all -n upbound-system
```

### Install the Multi-cloud Kubernetes Reference Platform

Now you can install this reference platform. It's packaged as a [Crossplane
configuration package](https://docs.crossplane.io/latest/concepts/packages/) so there is a single command to install it:

```console
up ctp configuration install xpkg.upbound.io/upbound/platform-ref-multi-k8s:v0.1.0
```

Validate the install by inspecting the provider and configuration packages:
```console
kubectl get providers,providerrevision

kubectl get configurations,configurationrevisions
```

Check the [marketplace](https://marketplace.upbound.io/configurations/upbound/platform-ref-multi-k8s/) for the latest version of this platform.

Before we can use the reference platform we need to configure it with AWS, GCP and Azure
### Configure the AWS provider

Example `creds.conf` should look similar to the structure below:

```console
# Create a creds.conf file with the aws cli:
AWS_PROFILE=default && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > creds.conf

# Create a K8s secret with the AWS creds:
kubectl create secret generic aws-creds -n upbound-system --from-file=credentials=./creds.conf

# Configure the AWS Provider to use the secret:
kubectl apply -f examples/aws-default-provider.yaml
```

See [provider-aws docs](https://marketplace.upbound.io/providers/upbound/provider-family-aws/latest/docs/configuration) for more detailed configuration options.

### Configure the GCP provider

Create a JSON `gcp.json` key file containing the GCP account credentials. GCP provides documentation on [how to create a key file](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating).

Example `gcp.json` key should look similar to the structure below:
```json
{
  "type": "service_account",
  "project_id": "caramel-goat-354919",
  "private_key_id": "e97e40a4a27661f12345678f4bd92139324dbf46",
  "private_key": "-----BEGIN PRIVATE KEY-----\n===\n-----END PRIVATE KEY-----\n",
  "client_email": "my-sa-313@caramel-goat-354919.iam.gserviceaccount.com",
  "client_id": "103735491955093092925",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/my-sa-313%40caramel-goat-354919.iam.gserviceaccount.com"
}
```

#### Create a K8s secret with the GCP creds:

```console
kubectl create secret generic gcp-creds -n upbound-system --from-file=credentials=./gcp.json
```

Ensure that the following roles are added to your service account:

* `roles/compute.networkAdmin`
* `roles/container.admin`
* `roles/iam.serviceAccountUser`
* `roles/iam.securityAdmin`
* `roles/iam.serviceAccountAdmin`
* `roles/iam.serviceAccountKeyAdmin`
* `roles/cloudsql.admin`

It is convenient to assign roles with `gcloud` CLI, e.g.

```console
gcloud projects add-iam-policy-binding --role="$ROLE" $PROJECT_ID --member "serviceAccount:$SA"
```

#### Configure the GCP Provider to use the secret:
```console
kubectl apply -f https://raw.githubusercontent.com/upbound/platform-ref-gcp/main/examples/gcp-default-provider.yaml
```

See [provider-gcp docs](https://marketplace.upbound.io/providers/upbound/provider-family-gcp/latest/docs/configuration) for more detailed configuration options.

### Configure the Azure provider

Example `azure.json` should look similar to the structure below:

```console
# Create a azure.json file with the azure cli:
# Replace <Subscription ID> with your subscription ID.
az ad sp create-for-rbac --sdk-auth --role Owner --scopes /subscriptions/<Subscription ID> \
  > azure.json

# Create a K8s secret with the Azure creds:
kubectl create secret generic azure-creds -n upbound-system --from-file=credentials=./azure.json

# Configure the Azure Provider to use the secret:
kubectl apply -f examples/azure-default-provider.yaml
```

See [provider-azure docs](https://marketplace.upbound.io/providers/upbound/provider-family-azure/latest/docs/configuration) for more detailed configuration options

## Using the Multi-cloud Kubernetes Reference Platform

🎉 Congratulations. You have just installed your first Crossplane-powered
platform!

Application developers can now use the platform to request resources which then
will be provisioned in AWS. This would usually be done by bundling a claim as part of
the application code. In our example here we simply create the claims directly:

Create a cluster in AWS:
```console
kubectl apply -f examples/aws-cluster.yaml
```

Create a cluster in GCP:
```console
kubectl apply -f examples/gcp-cluster.yaml
```

Create a cluster in Azure:
```console
kubectl apply -f examples/azure-cluster.yaml
```

You can verify the status by inspecting the claims, composites and managed
resources:

```console
kubectl get claim,composite,managed
```

To delete the provisioned resources you would simply delete the claims:

```console
kubectl delete -f examples/aws-cluster.yaml
kubectl delete -f examples/gcp-cluster.yaml
kubectl delete -f examples/azure-cluster.yaml
```

To uninstall the provider & platform configuration:

```console
kubectl delete configuration --all
kubectl delete providers --all
kubectl delete functions --all
```

## Customize for your Organization

So far we have used the existing reference platform but haven't made any
changes. Let's change this and customize the platform by ensuring the EKS
Cluster is deployed to Frankfurt (eu-central-1) and that clusters are limited
to 10 nodes.

For the following examples we are using `my-org` and `my-platform`:

```console
ORG=my-org
PLATFORM=my-platform
```

### Pre-Requisites
First you need to create a [free Upbound account](https://accounts.upbound.io/register) to push your custom platform.
Afterwards you can log in:

```console
up login --username=$ORG
```

### Make the changes

To make your changes clone this repository:

```console
git clone https://github.com/upbound/platform-ref-multi-k8s.git $PLATFORM && cd $PLATFORM
```

### Build and push your platform

To share your new platform you need to build and distribute this package.

To build the package use the `up xpkg build` command:

```console
up xpkg build --name package.xpkg --package-root=package --examples-root=examples
```

Afterwards you can push it to the marketplace. Don't worry - it's private to you.

```console
TAG=v0.1.0
up repo create ${PLATFORM}
up xpkg push ${ORG}/${PLATFORM}:${TAG} -f package/package.xpkg
```

You can now see your listing in the marketplace:
```console
open https://marketplace.upbound.io/configurations/${ORG}/${PLATFORM}/${TAG}
```

## Using your custom platform

Now to use your custom platform, you can follow the steps above. The only
difference is that you need to specify a package-pull-secret, as the package is
currently private:

```console
up ctp pull-secret create personal-pull-secret
```

```console
up ctp configuration install xpkg.upbound.io/${ORG}/${PLATFORM}:${TAG} --package-pull-secrets=personal-pull-secret
```

For the alternative declarative installation approach see the [example Configuration manifest](examples/configuration.yaml). Please update to your org, platform and tag before applying.

🎉 Congratulations. 
You have just built and installed your first custom Crossplane-powered platform!
