# Tutorial Cluster

This is a reference design for tutorial cluster than can accommodate up to 60 active users. It is expected that each will be doing a mixture of interactive (shell) and IDE-driven development, sending off computation and testing runs to batch jobs via Slurm. 

## Overview

To launch a cluster using this design, briefly:
1. Choose an SSH key for logging into the system
2. Set up networking for ParallelCluster
3. Launch an instance of AWS Microsoft Managed AD
4. Create a Amazon Elastic Filesystem (EFS) filesystem to hold user home directories
5. Using outputs from the previous steps, create the cluster

Except for the SSH key, all assets will be created using CloudFormation templates. 

## Choose or create an Amazon EC2 SSH key

Review the available SSH keys in the [Amazon EC2 Console](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#KeyPairs:). If you don't recognize any of these, create a new one. You will use this SSH key to log into management instances.

## Set up Networking

Our cluster design assumes you have a VPC with at two public subnets, each in different availability zones, and two private subnets, also in different availability zones. We have provided a CloudFormation template you can use to set this up.

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-networking&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/net/hpc_networking_2az/assets/public-private.cfn.yml)

## Set up AWS Microsoft Managed AD

To make our cluster a multi-user systemm, we integrate it with a directory service. ParallelCluster supports Microsoft Active Directory, and more importantly, supports AWS Microsoft Managed AD. We recommend you use the CloudFormation template we have provided here to set one up. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-ad&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/ad/demo_managed_ad/assets/main.yaml)

Notes:
1. Choose the VPC that was created using the networking stack above
2. Choose **private** subnets A & B, which were created in that VPC
3. For *EC2 Keypair to access management instance*, choose the SSH key from the first step in this document.
4. Go have a cup of tea (or two) after launching the stack creation - AD can take a while to provision. 
5. Note `DomainAddrLdap`, `DomainName`, `DomainReadOnlyUser`, and `PasswordSecretArn` from the CloudFormation stack outputs. You will need them later.

## Set up Amazon Elastic File System

To ensure users don't lose valuable data should we need to recreate the HPC cluster, we use an external filesystem for their home directories. Since our cluster can span availability zones, we use EFS for this persistent filesystem. We recommend you use the CloudFormation template we have provided here to set it up. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-home-efs&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/storage/efs/assets/main.yml)

Notes:
1. Choose the VPC that was created using the networking stack above
2. Choose **public** subnets A & B, which were created in that VPC
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

