# Tutorial Cluster

This is a reference design for tutorial cluster than can accommodate up to 60 active users. It is expected that each will be doing a mixture of interactive (shell) and IDE-driven development, sending off computation and testing runs to batch jobs via Slurm. 

## Overview

To launch a cluster using this design, briefly:
1. Set up networking for ParallelCluster (VPC and subnets)
2. Launch an instance of AWS Microsoft Managed AD 
3. Create a Amazon Elastic Filesystem (EFS) filesystem to hold user home directories
4. Using outputs from the previous steps, create the cluster

## Set up Networking

Our cluster design assumes you have a VPC with at two public subnets, each in different availability zones. We have provided a CloudFormation template you can use to set this up. You will use this VPC and the associated subnets for the persistent filesystem and cluster.

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-networking&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/net/hpc_networking_2az/assets/public-private.cfn.yml)

## Set up AWS Microsoft Managed AD

To make our cluster a multi-user systemm, we integrate it with a directory service. ParallelCluster supports Microsoft Active Directory, and more importantly, supports AWS Microsoft Managed AD. We recommend you use the CloudFormation template we have provided here to set one up. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-ad&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/ad/demo_managed_ad/assets/main.yaml)

Notes:
1. Choose the same SSH key for accessing the AD manager node as for your cluster
2. Note `DomainAddrLdap`, `DomainName`, `DomainReadOnlyUser`, and `PasswordSecretArn` from the CloudFormation stack outputs. You will need them later.

## Set up Amazon Elastic File System

To ensure users don't lose valuable data should we need to recreate the HPC cluster, we use an external filesystem for their home directories. Since our cluster can span availability zones, we use EFS for this persistent filesystem. We recommend you use the CloudFormation template we have provided here to set it up. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-home-efs&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/storage/efs/assets/main.yml)

Notes:
1. Choose the same VPC you will launcn your cluster in
2. Choose the same subnets for the filesystem as you will launch your cluster in.
3. Note `EFSFilesystemId` from the CloudFormation stack outputs. You will need it later.

## Set up the Cluster

With the prerequisite infrastructure in place, now we can create the HPC cluster. We have provided a CloudFormation template for this. It has several parameters. Some are mandatory, with a fixed value, while others can be used to tune the cluster's behavior. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=pcluster-networking&templateURL=https://pcm-release-us-east-1.s3.us-east-1.amazonaws.com/pcluster-manager.yaml)

Notes:
1. Meep

## Log into the Cluster

Notes

## Manage AD Users

Notes

## Install Shared Software

Notes

