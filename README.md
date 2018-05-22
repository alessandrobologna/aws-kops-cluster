# aws-kops-cluster
Building a playground on k8s on AWS


This repository contains the documentation on the steps thave have been used to 
install [kops](https://github.com/kubernetes/kops) on a AWS environment.
As such, it is very much of a work in progress. It does feature, at this stage, heaspster, the kubernetes dashboard, cloudwatch logs integration using fluentd, statsd metrics and datadog agent.

For documentation on Kops please refer to these [docs](https://github.com/kubernetes/kops/tree/master/docs) and [these others](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/aws_under_the_hood.md) for an "under the hood" understanding.

### Install kops
```bash
$ brew update && brew install kops
```
The current version for kops is `1.8.0`. The version of the kubernetes cluster is `1.8.6`. 
Installing kops with brew will also install `kubectl`

These clusters are set as HA clusters in 3 AZs, with 3 master nodes, and within 3 private subnets in a kops managed VPC. 
For ecommerce, the clusters are set up in us-east-2 (Ohio).

---
## Preparation
_This section is for the reader who wants to understand how it was done._

Depending on the AWS account on which to build the cluster, set the corresponding `AWS_PROFILE`:
```bash
$ export AWS_PROFILE=<your-profile>
```

### Set up
To use the same ssh keys as you may already be using in other AWS environments, run:
```bash
$ ssh-keygen -y -f /path/to/pemfile.pem > /path/to/pemfile.pub
```
Now export some useful variables: 
```bash
$ export DOMAIN=<domain.for.cluster> 
$ export NAME=<name-for-cluster> 
$ export KOPS_STATE_STORE=s3://state-store.${NAME}.${DOMAIN} 
$ export ZONES="us-east-2a,us-east-2b,us-east-2c"
```
Create a bucket for the state store:
```bash
$ aws s3api create-bucket --bucket state-store.${NAME}.${DOMAIN}
```
Add versioning to the bucket:
```bash
$ aws s3api put-bucket-versioning --bucket state-store.${NAME}.${DOMAIN} --versioning-configuration Status=Enabled
```
### Create the cluster
This example create a Kubernetes cluster with 3 worker nodes, a private and a public subnet in each zone, using m4.large instance types, within a custom CIDR block if provided.
More information here: [docs](https://github.com/kubernetes/kops/blob/master/docs/cli/kops_create_cluster.md):

```
 $ kops create cluster \
  --node-count 3 \
  --zones $ZONES \
  --master-zones $ZONES \
  --node-size t2.micro \
  --master-size t2.micro \
  --ssh-public-key /path/to/pemfile.pub \
  --topology private \
  --networking weave \
  --bastion \
  --name $NAME.$DOMAIN \
  --network-cidr <address/bits> 
 ```

Notice the for private clusters you cannot use the default networking, and we are using [weave](https://github.com/weaveworks/weave) instead.

Review the configuration:
```bash
$ kops edit cluster --name $NAME
```
Finally, execute your changes with `kops update cluster --name $NAME.$DOMAIN --yes`.

### Optionally add CloudWatch permissions:
To have all the cluster logs sent to CloudWatch, you will need to add this configuration by running `kops edit cluster --name $NAME`:

```yaml
spec:
  additionalPolicies:
    master: |
      [
       {
          "Effect": "Allow",
          "Action": ["logs:*"],
          "Resource": ["*"]
        }
      ]
    node: |
      [
        {
          "Effect": "Allow",
          "Action": ["logs:*"],
          "Resource": ["*"]
        }
      ]
```
and then run `make deploy` in the [logging](logging) directory to install a fluentd based log collector that outputs to cloudwatch.

Confirm creation of the cluster:
```bash
$ kops update cluster ${NAME} --yes
```
Finally, wait until the cluster is ready and running (it will take a few minutes):
```bash
$ kops validate cluster
```
Please note that AWS, by default, will limit the number of EIP (elastic Ips) available in an account to 5. Each VPC will have 3 NatGateway which will take 3 of them. 
So, it's better to request a limit increase in advance.

### Addons
For all kops addons, see the [current recommended version](https://github.com/kubernetes/kops/blob/master/docs/addons.md)

#### Install Heapster to support horizontal pod autoscaling:

```bash
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.7.0.yaml
```

#### Install a nice UI for Kubernetes:
```bash
$ kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.8.1.yaml
```

Test it running `kubectl proxy` and opening a browser to `http://localhost:8001/ui`

### Switching betwen contexts
To list the available kubectl contexts, use:

```bash
$ kubectl config get-contexts
```
To switch the active kubectl context, use:
```bash
$ kubectl config use-context <name>
```

