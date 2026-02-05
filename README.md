# Terraform Infrastructure Code

This repository contains Terraform configurations for deploying infrastructure on AWS and Azure cloud platforms. The code is organized into reusable modules and environment-specific configurations.

## Project Structure

```
.
├── AWS/                          # AWS-specific configurations
│   ├── environments/             # Environment-specific deployments
│   │   ├── prod/                 # Production environment
│   │   │   ├── main.tf          # Main Terraform configuration
│   │   │   ├── variables.tf     # Variable definitions
│   │   │   └── prod.tfvars      # Production-specific variable values
│   │   └── test/                # Test environment
│   └── modules/                  # Reusable AWS modules
│       └── LamdaFunctions/      # AWS Lambda function module
├── Azure/                        # Azure-specific configurations
│   ├── environments/             # Environment-specific deployments
│   │   └── test/                 # Test environment
│   │       ├── main.tf          # Main Terraform configuration
│   │       ├── provider.tf      # Provider configuration
│   │       ├── variables.tf     # Variable definitions
│   │       ├── test.tfvars      # Test-specific variable values
│   │       └── test.tfvars.example  # Example variable values
│   └── modules/                  # Reusable Azure modules
│       ├── compute/              # Compute resources
│       │   ├── AppService/       # Azure App Service module
│       │   └── VM/               # Virtual Machine module
│       ├── monitoring/           # Monitoring resources
│       │   ├── ApplicationInsights/  # Application Insights module
│       │   ├── DiagnosticSettings/   # Diagnostic Settings module
│       │   └── LogAnalytics/     # Log Analytics module
│       ├── networking/           # Networking resources
│       │   ├── FrontDoor/        # Azure Front Door module
│       │   ├── TrafficManager/   # Traffic Manager module
│       │   └── VNet/             # Virtual Network module
│       └── storage/              # Storage resources
│           └── StorageAccount/   # Storage Account module
└── README.md                     # This file
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS CLI configured (for AWS deployments)
- Azure CLI configured (for Azure deployments)

### Required Providers

- **AWS Provider**: `hashicorp/aws` ~> 5.0
- **Azure Provider**: `hashicorp/azurerm` ~> 3.0

## AWS Deployments

### Lambda Functions

The AWS section includes a reusable Lambda function module that can deploy serverless functions with the following features:

- Custom runtime and handler configuration
- VPC deployment support
- Environment variables
- IAM roles and policies
- CloudWatch logging
- Dead letter queues
- X-Ray tracing
- Function aliases and versions

#### Deploying to Production

1. Navigate to the production environment:
   ```bash
   cd AWS/environments/prod
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the deployment plan:
   ```bash
   terraform plan -var-file=prod.tfvars
   ```

4. Apply the configuration:
   ```bash
   terraform apply -var-file=prod.tfvars
   ```

#### Deploying to Test

1. Navigate to the test environment:
   ```bash
   cd AWS/environments/test
   ```

2. Follow the same steps as production, using `test.tfvars`

## Azure Deployments

### Infrastructure Components

The Azure section includes modules for deploying various Azure resources:

- **Compute**: Virtual Machines and App Services
- **Networking**: Virtual Networks, Front Door, Traffic Manager
- **Storage**: Storage Accounts
- **Monitoring**: Application Insights, Log Analytics, Diagnostic Settings

#### Deploying to Test Environment

1. Navigate to the test environment:
   ```bash
   cd Azure/environments/test
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the deployment plan:
   ```bash
   terraform plan -var-file=test.tfvars
   ```

4. Apply the configuration:
   ```bash
   terraform apply -var-file=test.tfvars
   ```

### Backend Configuration

The Azure configurations use Azure Storage as the Terraform backend for state management. Configure the backend settings in your `terraform.tfvars` file or use environment variables:

```hcl
backend "azurerm" {
  resource_group_name  = "tfstate-rg"
  storage_account_name = "tfstatestorage"
  container_name       = "tfstate"
  key                  = "test.terraform.tfstate"
}
```

## CI/CD Pipelines

This repository includes Azure DevOps pipeline templates for automated Terraform deployments with proper security practices.

### Pipeline Structure

```
pipeline/
├── azure-pipeline.yml              # Main pipeline orchestration
├── terraform-plan.yml.txt          # Template for terraform plan operations
└── terraform-apply.yml.txt         # Template for terraform apply operations
```

### Features

- **Automated Testing**: Runs `terraform fmt`, `validate`, and `plan` on pull requests
- **Secure Authentication**: Uses Workload Identity Federation (WIF/OIDC) for Azure authentication
- **Environment Separation**: Separate pipelines for test and production environments
- **Modular Templates**: Reusable templates for plan and apply operations
- **State Management**: Configurable backend storage for Terraform state files

### Pipeline Templates

#### Main Pipeline (`azure-pipeline.yml`)

The main pipeline orchestrates the CI/CD process with the following stages:

- **Terraform Plan TEST**: Validates and plans changes for the test environment
- **Terraform Apply TEST**: Applies changes to test environment (currently commented out)

#### Terraform Plan Template (`terraform-plan.yml.txt`)

This template performs:
- Terraform installation
- Code formatting check (`terraform fmt`)
- Initialization with remote backend
- Validation (`terraform validate`)
- Planning (`terraform plan`) with variable files

#### Terraform Apply Template (`terraform-apply.yml.txt`)

This template performs:
- Terraform installation
- Code formatting check
- Initialization with remote backend
- Validation
- Application of changes (`terraform apply`)

### Authentication

The pipelines use Azure Workload Identity Federation for secure authentication:
- No long-lived secrets required
- Automatic credential rotation
- Enhanced security posture

### Configuration Variables

Set the following variables in your Azure DevOps pipeline:

- `terraformVersion`: Terraform version to use (default: 1.7.5)
- `testbackendRG`: Resource group for test environment state
- `testbackendSA`: Storage account for test environment state
- `testbackendContainer`: Container for test environment state
- `testazureServiceConnection`: Azure service connection name
- `testsubscriptionid`: Azure subscription ID for test environment

### Usage

1. **Import Pipeline**: Copy `azure-pipeline.yml` to your Azure DevOps repository
2. **Configure Variables**: Set up pipeline variables for your environments
3. **Service Connections**: Create Azure service connections with Workload Identity
4. **Enable Triggers**: Uncomment and configure apply stages as needed
5. **Run Pipeline**: Trigger manually or on pull request/merge

### Security Best Practices

- Use separate service connections for different environments
- Implement approval gates for production deployments
- Enable branch protection rules
- Regularly rotate credentials
- Monitor pipeline logs for security events

## Modules

### AWS Modules

- **LambdaFunctions**: Deploys AWS Lambda functions with comprehensive configuration options

### Azure Modules

- **VNet**: Creates Virtual Networks with subnets and Network Security Groups
- **VM**: Deploys Virtual Machines with associated resources
- **AppService**: Creates Azure App Services and deployment slots
- **StorageAccount**: Provisions Azure Storage Accounts
- **ApplicationInsights**: Sets up application monitoring
- **LogAnalytics**: Creates Log Analytics workspaces
- **DiagnosticSettings**: Configures diagnostic logging for resources
- **FrontDoor**: Deploys Azure Front Door for global distribution
- **TrafficManager**: Creates Traffic Manager profiles for load balancing

## Variables

Each environment has its own `variables.tf` file defining the required and optional variables. Environment-specific values are provided in `.tfvars` files.

For Azure test environment, you can copy `test.tfvars.example` to `test.tfvars` and modify the values according to your requirements.

## Security Considerations

- Review IAM roles and policies before deployment
- Use secure methods for storing sensitive variables
- Enable encryption for storage resources
- Configure appropriate network security groups
- Enable logging and monitoring for compliance

## Contributing

1. Follow the established module structure
2. Use consistent naming conventions
3. Include comprehensive variable definitions
4. Add appropriate tags to resources
5. Test modules in isolated environments before production deployment

## License

This project is licensed under the MIT License - see the LICENSE file for details.