# Tutorial Cluster

This is a reference design for tutorial cluster than can accommodate up to 60 active users. It is expected that each will be doing a mixture of interactive (shell) and IDE-driven development, sending off computation and testing runs to batch jobs via Slurm. 

A few key features include:
- Longer (but configurable) scale-down period to hold on to nodes while the cluster is in active use
- Configurable maximum job length (to prevent users from leaving jobs running forever)
- Multi-user support using AWS Managed Microsoft Active Directory
- Support for administrator login via AWS Systems Manager
- A substantial head node to support user sessions
- Persistent home directories built on Amazon EFS
- Modest FSx for Lustre shared storage for workloads requiring low-latency IO.

## Overview

To launch a cluster using this design, briefly:
1. Create or select an SSH key for logging into the system as administrator
2. Set up networking for ParallelCluster using a CloudFormation stack
3. Launch an instance of AWS Microsoft Managed AD using a CloudFormation stack
4. Create a Amazon Elastic Filesystem (EFS) filesystem using a CloudFormation stack
5. Using outputs from the previous steps, create the cluster.

## Choose or create an Amazon EC2 SSH key

Review the available SSH keys in the [Amazon EC2 Console](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#KeyPairs:). If you don't recognize any of these, create a new one. You will use this SSH key to log into management instances.

## Set up Networking

Our cluster design assumes you have a VPC with at least one public and two private subnets (in different availability zones). We will use the CloudFormation template from the HPC Recipes on AWS library to set this up.

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=hpc-networking&templateURL=https://aws-hpc-recipes.s3.us-east-1.amazonaws.com/main/recipes/net/hpc_large_scale/assets/main.yaml)

Name your stack something memorable, like `hpc-networking` as you will need the name later.

## Set up AWS Microsoft Managed AD

To make our cluster a multi-user systemm, we integrate it with a directory service. ParallelCluster supports Microsoft Active Directory, and more importantly, supports AWS Microsoft Managed AD. We will use the CloudFormation template from the HPC Recipes on AWS library to set this up. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=managed-ab&templateURL=https://aws-hpc-recipes.s3.us-east-1.amazonaws.com/main/recipes/dir/demo_managed_ad/assets/main-import.yaml)

Name your stack something memorable, like `managed-ad` as you will need the name later.

Notes:
1. Provide the name of your networking stack
2. Leave the values for **UserName** and **UserPassword** totally empty. Users are provided by the LDIF file.
3. Provide a strong password for **AdminPassword** and **ServiceAccountPassword**
4. For *EC2 Keypair to access management instance*, choose the SSH key from the first step in this document.
5. Go have a cup of tea (or two) after launching the stack - AD can take a while to provision. 

## Set up Amazon Elastic File System

We use an external filesystem for user home directories. Since our cluster can span availability zones, we use EFS. We recommend you use the CloudFormation template we have provided here to set it up. 

[![Launch](https://samdengler.github.io/cloudformation-launch-stack-button-svg/images/us-east-2.svg)](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/create/review?stackName=tutorial-home-efs&templateURL=https://cfn3-dev-mwvaughn.s3.us-east-2.amazonaws.com/main/recipes/storage/efs/assets/main.yml)

Name your stack something memorable, like `home-efs` as you will need the name later.

Notes:
1. Choose the VPC that was created using the networking stack above
2. Choose **private** subnets A & B, which were created in that VPC (also using the networking stack)

This will create an EFS filesystem with mount targets in each subnets. It also create a self-referencing security group that your cluster nodes will join to grant them access to the filesystem.

## Set up the Cluster

With the prerequisite infrastructure in place, now we can create the HPC cluster. We have provided a template for this, which you can upload to CloudFormation.
1. Navigate to the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation/home?region=us-east-2)
2. Choose **Create stack** (with new resources)
3. Choose **Upload a template file** then upload the file `cfn/cluster.yaml` from this repository.
4. Choose **Next** then fill out the template as it instructs you to.
5. Continue on to the end of the CloudFormation stack launch worklow to launch the cluster via this stack.

Notes:

The CloudFormation template is organized into distinct sections to help guide you in setting up the system. 
- HPC Recipes for AWS CloudFormation Stacks
- Cluster Head Node
- Cluster Queues and Compute Nodes

Provide the names of the relevant CloudFormation stacks, then finish parameterizing the cluster launch.

Monitor the status of your stack. Once it reaches `CREATE_COMPLETE`, you can access the cluster. 

## Log into the Cluster

You have two options to log into the cluster as an admninistrator: SSH or AWS Systems Manager (SSM). The former is the traditional access mechanism for HPC systems, where you use a local terminal and SSH client. SSM allows you to log into your cluster directly from the AWS Console, even if the instance is not publicly accessible via the Internet. 

### SSH

Navigate to the **Outputs** section of your cluster CloudFormation stack. The value of `HeadNodeIp` is the public IP address of your head node. You can log into the cluster using your SSH key, the IP address, and the default user name for the instance. 

`ssh -i MY-SSH-KEY.pem DEFAULT-USERNAME@IP.ADDRESS`

The default username will vary depending on the cluster operating system:
- Amazon Linux 2: `ec2-user`
- Centos7: `centos`
- Ubuntu 18 and Ubuntu 20: `ubuntu` 

### Amazon SSM

Navigate to the [Amazon EC2 console](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Instances:instanceState=running) to find your running instances. Select the instance named **HeadNode**, then choose **Connect**. Now, choose the **Session Manager** tab. Finally, choose **Connect**. You will be logged into the head node in a browser-based terminal.

## Manage AD Users

Users managed via AD will be able to log in via SSH to the cluster head node using the username and password you assign them. 

`ssh AD-MANAGED-USERNAME@IP.ADDRESS`

First, you have to provision some users! You can use the AD management node to do this. The management node is inaccessible from the public internet, but you can access it via the AWS Console. Navigate to the [Amazon EC2 console](https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Instances:instanceState=running) to find your running instances. Select the instance whose name begins with **AdDomainAdminNode**, then choose **Connect**. Now, choose the **Session Manager** tab. Finally, choose **Connect**. You will be logged into the AD management node in a browser-based terminal.

### Add a user

`adcli create-user "clusteruser" --domain "corp.pcluster.com" -U "Admin"`

You will be prompted for a password. Provide the value you used for `AdminPassword` when you set up your Active Directory. If you want to script user creation, note that `adcli` has a command-line option that lets you pass in the administrator password via `STDIN`.

### Change a user password

You will need the ID for the directory you have created. You can find it under `Outputs/DirectoryId` in the CloudFormation stack you used to it up. 

`aws --region "us-east-2" ds reset-user-password --directory-id "d-abcdef01234567890" --user-name "clusteruser" --new-password "new-p@ssw0rd"`

### Other operations

You can do other administrative tasks from the management node. We recommend you consult the **Manage AD users and groups** section of tutorial **[Integrating Active Directory](https://docs.aws.amazon.com/parallelcluster/latest/ug/tutorials_05_multi-user-ad.html)** to learn more. 

## Shared Storage

There are two shared filesystems on the cluster:
* `/shared/home` - Amazon EFS. Used for AD user home directories. Also usable for shared software (you will have to manage a directory structure for that yourself)
* `/shared/work` - Amazon FSx for Lustre. High-speed Lustre filesystem. All users should have read/write access to it. 

