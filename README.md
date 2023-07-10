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

Notes:

If you use the default values provided by the CloudFormation template, you will create the following.

```
tutorial-networking-HPC-VPC [10.3.0.0/16]
  - tutorial-networking-Public-SubnetA [10.3.128.0/20]
  - tutorial-networking-Public-SubnetB [10.3.144.0/20]
  - tutorial-networking-Private-SubnetA [10.3.0.0/18]
  - tutorial-networking-Private-SubnetB [10.3.64.0/18]
```

## Set up AWS Microsoft Managed AD

To make our cluster a multi-user systemm, we integrate it with a directory service. ParallelCluster supports Microsoft Active Directory, and more importantly, supports AWS Microsoft Managed AD. We recommend you use the CloudFormation template we have provided here to set one up. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-ad&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/ad/demo_managed_ad/assets/main.yaml)

Notes:
1. Choose the VPC that was created using the networking stack above
2. Choose **private** subnets A & B, which were created in that VPC
3. For *EC2 Keypair to access management instance*, choose the SSH key from the first step in this document.
4. Go have a cup of tea (or two) after launching the stack creation - AD can take a while to provision. 
5. Note `DomainAddrLdap`, `DomainName`, `DomainReadOnlyUser`, and `PasswordSecretArn` from the CloudFormation stack outputs. You will need them later.

This will create three resources: Two redundant Microsoft Active Directory contollers, one in each subnet, and a management instance for the directory, which will launch in private subnet A. Launching in private subnets helps keep your directory service secure by preventing unwanted access attenpts. 

## Set up Amazon Elastic File System

We use an external filesystem for user home directories. Since our cluster can span availability zones, we use EFS. We recommend you use the CloudFormation template we have provided here to set it up. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-home-efs&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/storage/efs/assets/main.yml)

Notes:
1. Choose the VPC that was created using the networking stack above
2. Choose **public** subnets A & B, which were created in that VPC
3. Note `EFSFilesystemId` from the CloudFormation stack outputs. You will need it later.

This will create an EFS filesystem with mount targets in each of the public subnets. 

## Set up the Cluster

With the prerequisite infrastructure in place, now we can create the HPC cluster. We have provided a template for this, which you can upload to CloudFormation.
1. Navigate to the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation/home?region=us-east-2)
2. Choose **Create stack** (with new resources)
3. Choose **Upload a template file** then upload the file `cfn/cluster.yaml` from this repository.
4. Choose **Next** then fill out the template as it instructs you to.
5. Continue on to the end of the CloudWatch stack launch worklow to launch the cluster via this stack.

Notes:

The CloudFormation template is organized into distinct sections to help guide you in setting up the system. 
- Active Directory
- Amazon Elastic Filesystem
- Head Node
- Compute Nodes and Queues
- Miscellaneous

Monitor the status of your stack. Once it reaches `CREATE_COMPLETE`, you can log into the cluster.

## Log into the Cluster

You have two options to log into the cluster as an admninistrator: SSH or Amazon SSM. The former is the traditional access mechanism for HPC systems, where you use a local terminal and SSH client. Amazon SSM allows you to log into your cluster directly from the AWS Console. 

### SSH

Navigate to the **Outputs** section of your cluster CloudFormation stack. The value of `HeadNodeIp` is the public IP address of your head node. You can log into the cluster using your SSH key, the IP address, and the default user name for the instance. 

`ssh -i MY-SSH-KEY.pem USERNAME@IP.ADDRESS`

The username will vary depending on the cluster operating system:
- Amazon Linux 2: `ec2-user`
- Centos7: `centos`
- Ubuntu 18 and Ubuntu 20: `ubuntu` 

### Amazon SSM

Navigate to the [Amazon EC2 console](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Instances:instanceState=running) to find your running instances. Select the instance named **HeadNode**, then choose **Connect**. Now, choose the **Session Manager** tab. Finally, choose **Connect**. You will be logged into the head node in a browser-based terminal.

## Manage AD Users

You can use the AD management node to add, remove, and update cluster users. It has `adcli` and `openldap-clients` tools pre-installed and is configured to communicate with the AD controllers. 

The management node is inaccessible from the public internet, but you can access it via the AWS Console. Navigate to the [Amazon EC2 console](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Instances:instanceState=running) to find your running instances. Select the instance whose name begins with **AdDomainAdminNode**, then choose **Connect**. Now, choose the **Session Manager** tab. Finally, choose **Connect**. You will be logged into the AD management node in a browser-based terminal.

### Add a user

`adcli create-user "clusteruser" --domain "corp.pcluster.com" -U "Admin"`

You will be prompted for a password. Provide the value you used for `AdminPassword` when you set up your Active Directory. If you want to script user creation, note that `adcli` has a command-line option that lets you pass in the administrator password via `STDIN`.

### Change a user password

You will need the ID for the directory you have created. You can find it under `Outputs/DirectoryId` in the CloudFormation stack you used to it up. 

`aws --region "us-east-2" ds reset-user-password --directory-id "d-abcdef01234567890" --user-name "clusteruser" --new-password "new-p@ssw0rd"`

### Other operations

You can do other administrative tasks from the management node. We recommend you consult the **Manage AD users and groups** section of tutorial **[Integrating Active Directory](https://docs.aws.amazon.com/parallelcluster/latest/ug/tutorials_05_multi-user-ad.html)** to learn more. 

## Install Shared Software

In addition to the persistent EFS filesystem used for user home directories, we also create a shared filesystem for software. It is mounted at `/shared/efs/apps`. You can put whatever else you want to here, but we have taken the liberty of pre-installing Spack on it at `/shared/efs/apps/spack`. To do so, we used the Spack configs described in the AWs HPC Blog post *[Install optimized software with Spack configs for AWS ParallelCluster](https://aws.amazon.com/blogs/hpc/install-optimized-software-with-spack-configs-for-aws-parallelcluster/)*.

