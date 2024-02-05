# 3 Tier Web app in Azure - IaaS + Azure SQL

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Usage](#usage)
- [License](#license)

## Overview

This is a follow-along project for a simple 3-tier web application, as explained in the Microsoft Learn documentation [Deploy an N-tier architecture][Deploy an N-tier architecture]. The objective of this project is to become more familiar with designing, deploying, and connecting a 3-tier architecture in Azure while preparing for the Azure Architect Expert certification. The project is deployed and written with Terraform. The original document was written in ARM, and some other examples can be found using Bicep. A 3-tier architecture divides the application into three layers, allowing for a more secure and efficient architecture. The main objectives of this project are:

- Learn how to design and connect 3-tier applications.
- Enhance proficiency in deploying Infrastructure as Code (IaC) using Terraform.
- Gain insights into Azure's 3-Tier App Deployment using IaaS (VMs) and PaaS (Azure SQL).

Self-development and hands-on practice are the core focus of this project. I recommend checking the commands.sh file in this project, where I've documented troubleshooting notes that could be helpful in understanding how this 3-tier app connects and functions, along with some troubleshooting commands for the ASP.NET-based application.

## Architecture

![Architecture Diagram](<https://github.com/MTD777/three-tier-azure-app1/blob/main/images/3-tier-webapp.drawio.png>)

Describe the components of the architecture and how they interact.

## Getting Started

You will need terraform, git, and an Azure subscription to deploy this project app.

## Deployment

You may deploy this PoC app in your Azure subscriptiong by cloning this repository and deploying using terraform (I will not cover how to set up Terraform, but you can download it [here](<https://developer.hashicorp.com/terraform/downloads>) and help to set it up [here](<https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell-bash?tabs=bash>)), overall steps using Azure CLI should be:

```
# Clone repo. 

git clone https://github.com/MTD777/three-tier-azure-app1

# Navigate to the root folder of the project

cd three-tier-azure-app1

# Login to your Azure account and set your subscription

az login
az account show
az account set --subscription "Replace_with_your_Subscription_ID"

# Initialize deployment - initializes a working directory containing Terraform configuration files

terraform init

# Validate terraform for syntax errors

terraform validate

# Makes a "plan" of our deployment (Think of it as a preview of what our deployment will do, it will check the syntax for errors and allow us to check the resources that will be deployed but without deployed them yet)

terraform plan -out=tfplan

# Applies our deployment plan

terraform apply "tfplan"

```

## Usage

If your objectives align with the ones explained in the overview section, I would recommend copying and deploying this project. Alternatively, you can deploy it directly from the MS Learn documentation using ARM. Explore the main, outputs, variables, and providers Terraform files in this project, and modify them according to your project or lab requirements.

Once you deploy this project, you can SSH/login to the frontend VM. From there, SSH to the BackendVM. Explore the application settings on both the frontend and backend, and observe how the connection between them is defined using .NET (Check the commands.sh file to find the file's locations).

If you want to learn more about cloud deployment and management, you can expand this project to send all application logs to the already deployed log analytics workspace. Otherwise, feel free to explore any exercises that come to your mind. Remember, the sky is the limit :-)

## License

This project is licensed under the [MIT License](LICENSE).

[Deploy an N-tier architecture]: https://learn.microsoft.com/en-us/training/modules/n-tier-architecture/3-deploy-n-tier-architecture
