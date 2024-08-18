# Terraform AWS Project

Outlines the steps to set up and deploy a web server cluster using Terraform and AWS.

## Table of Contents
1. [Install Terraform](#install-terraform)
2. [AWS Access Key Setup](#aws-access-key-setup)
3. [AWS Configure](#aws-configure)
4. [Writing Terraform Code](#writing-terraform-code)
5. [Deploying Web Server](#deploying-web-server)
6. [Deploying a Cluster of Webservers](#deploying-a-cluster-of-webservers)
7. [Deploying Load Balancer](#deploying-load-balancer)
8. [Configuring the State File](#configuring-the-state-file)
9. [Working with Workspaces](#working-with-workspaces)
10. [Setting Up RDS](#setting-up-rds)
11. [Deployment by Templatefile](#deployment-by-templatefile)

## Install Terraform

1. I used Git Bash as IDE on Windows (Run as administrator)
2. Install Terraform:
   ```
   choco install terraform
   ```
   ![terraforminstall](/images/terraforminstall.png)
3. Verify installation:
   ```
   terraform --version
   ```
   ![terraformversion](/images/terraform-version.png)
   

## AWS Access Key Setup

1. Access AWS IAM
2. Create new access keys for CLI use
3. Download the .csv file with access keys

   ![aws](/images/iam1.png)
   ![aws](/images/iam2.png)
   ![aws](/images/iam3.png)
   ![aws](/images/iam4.png)
   ![aws](/images/iam5.png)
   ![aws](/images/iam6.png)
   

## AWS Configure

Configure AWS CLI with your access keys:
```
aws configure
```
Enter:
- Access Key ID
- Secret Access Key
- Region name
- Output format (leave default)

   ![aws](/images/aws-configure.png)


## Writing Terraform Code

1. Create `main.tf` file
2. Define provider and region:
   ```hcl
   provider "aws" {
     region = "us-east-1"
   }
   ```
3. Define resources (e.g., EC2 instance)
   ![terraform](/images/terraform-provider.png)
   ![terraform](/images/terraform-resource.png)


## Deploying Web Server

1. Update `main.tf` with web server configuration
2. Run `terraform init`
3. Run `terraform plan`
4. Run `terraform apply`

   ![terraforminit](/images/terraform-init.png)
   ![terraformplan](/images/terraform-plan.png)
   ![terraformapply](/images/terraform-apply1.png)

5. Instance running after terraform apply but noticed a name hasn't been assigned.

   ![aws](/images/ec2deployed.png)

6. Added tags to provider block of terraform code.
   ![terraform](/images/addsnametoinstance.png)

7. Run `terraform apply` again to make the update.
   ![terraform](/images/terraform-apply-name.png)
   ![terraform](/images/ec2deployed-name.png)


## Deploying a Cluster of Webservers

1. Update `main.tf` to use `aws_launch_configuration` and `aws_autoscaling_group`
    - Added Security Group and User Data resource to terraform code.
   ![terraform](/images/corrected-terrafom-code.png)
   ![terraform](/images/ec2SG.png)

    - Create `variables.tf` file to hold `server_port` Possessing the port number 8080 in both the user data and security group violates the DRY principle (don't repeat yourself).
       ![terraform](/images/variable1.png)
        ![terraform](/images/variable2.png)
        ![terraform](/images/variable3.png)
    - Create `aws_launch_configuration` and `aws_autoscaling_group`
            ![terraform](/images/launchconfig.png)
            ![terraform](/images/asg.png)



2. Create `data_sources.tf` to pull VPC and subnet data

        ![terraform](/images/datasources.png)

3. Apply changes with `terraform apply`


## Deploying Load Balancer

1. Add load balancer configuration to `main.tf`
2. Apply changes and test the load balancer DNS

    ![terraform](/images/lb.png)
    ![terraform](/images/lb2.png)
    ![terraform](/images/lb3.png)
    ![terraform](/images/lb4.png)

    - Output of the Load Balancer DNS:
    ![terraform](/images/dns.png)

    - Cluster up and running:
    ![aws](/images/2instances.png)
    
    - Load Balancer
    ![aws](/images/loadbalancer.png)

     - Target Group
    ![aws](/images/targetgroup.png)

     - Targets
    ![aws](/images/targets.png)

    - Test to confirm load balancer is working:
    ![aws](/images/SUCCESS.png)


## Configuring the State File

1. Create S3 bucket for remote backend
2. Update backend configuration in Terraform
3. Initialize and apply changes

    - The s3 bucket  will be my remote backend meaning the s3 will load and store my state file in a shared store. This reduces manual error or misconfiguration, promote locking if someone was to terraform appy if currently running, and encryption.

    ![terraform](/images/state1.png)
    ![terraform](/images/state2.png)
    ![terraform](/images/s3.png)
    ![terraform](/images/state3.png)

    - Dynamo DB table
    ![terraform](/images/db.png)




## Working with Workspaces

1. Create new workspaces:
   ```
   terraform workspace new <workspace_name>
   ```
2. List workspaces:
   ```
   terraform workspace list
   ```
3. Switch between workspaces:
   ```
   terraform workspace select <workspace_name>
   ```

    ![terraform](/images/wp1.png)

    - Since I am in a new workspace, terraform wants to create a new instance because the statefiles are isolated. It’s not using the state file from the default workspace.
    Terraform plan shows that a new instance will be created.
    ![terraform](/images/wp2.png)
    ![terraform](/images/wp3.png)

    - `terraform workspace select <workspace name>` will allow you to switch between workspaces.
    ![terraform](/images/wp4.png)
    - Now we have a folder in the S3 bucket of our workspaces called .env. It’s like changing the path where the state file is store
    ![terraform](/images/wp5.png)


    

## Setting Up RDS

1. Set environment variables for database credentials:
   ```
   set TF_VAR_db_username="your_username"
   set TF_VAR_db_password="your_password"
   ```
2. Update Terraform configuration for RDS
3. Apply changes

    ![terraform](/images/rd1.png)

    - Amazon RDS is now created we notice it outputs the rds address and the port number it’s on.

    ![terraform](/images/rd3.png)

## Deployment by Templatefile
1. Create Bash Script to pass User Data.
2. Update `main.tf`

    ![terraform](/images/bash.png)
    ![terraform](/images/bash2.png)
    ![terraform](/images/success2.png)


## Challenges

1. Received errors with target where it became unhealthy checks and unable to open webpage. Suspect different regions between S3 being in us-west-2 and cluster in us-east-1. After creating a new terraform project with the correct region, my deployment worked. The web server cluster can now access the database address and port via terraform.

2. This error means the instance type is supported. Supports db.t3.micro instead of db.t2.micro:
![terraform](/images/rd2.png)

3. This error means quotations are missing around a resource name or variable:
![terraform](/images/error.png)

4. Received another error at line 9, I forgot to add “id" at the end:
![terraform](/images/error2.png)

## Clean Up

To destroy resources:
```
terraform destroy
```

Remember to switch to each workspace and run `terraform destroy` to clean up all resources.

