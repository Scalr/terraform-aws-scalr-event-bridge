# Terraform AWS Scalr EventBridge Integration Module

This Terraform module creates an integration between AWS EventBridge and Scalr, allowing automatic state file backups to S3 when Terraform runs are executed in Scalr. The module is designed to be secure, maintainable, and follows infrastructure-as-code best practices.

## Features

- **EventBridge Integration**
  - Creates a custom event bus for Scalr events
  - Configures event rules for state file updates
  - Sets up event targets with retry policies
  - Implements dead letter queue for failed events

- **Lambda Function**
  - Processes Scalr events and manages state files
  - Uses Python 3.11 runtime
  - Configurable timeout and memory settings
  - X-Ray tracing enabled
  - CloudWatch monitoring and alerting

- **S3 Storage**
  - Secure state file storage with KMS encryption
  - Configurable bucket naming
  - Lifecycle policies for state file retention
  - Server-side encryption enabled

- **Security**
  - KMS encryption for sensitive data
  - IAM roles with least privilege
  - Service account with read-only access
  - Secure token handling
  - S3 bucket encryption

## Usage

```hcl
module "scalr_eventbridge" {
  source = "github.com/Scalr/terraform-aws-scalr-eventbridge"

  # Required parameters
  region      = "us-east-1"
  bridge_name = "my-scalr-integration"

  # Optional parameters
  s3_bucket_name       = "my-custom-bucket-name"
  lambda_timeout       = 300
  lambda_memory        = 256
  log_retention        = 30
  state_retention_days = 90
}
```

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5.0 |
| aws       | >= 5.0.0 |
| scalr     | >= 3.0.0 |
| random    | >= 3.0.0 |

## Inputs

| Name                 | Description                                | Type     | Default | Required |
|----------------------|--------------------------------------------|----------|---------|:--------:|
| region               | AWS region to deploy resources             | `string` | n/a     |   yes    |
| bridge_name          | Name of the EventBridge integration        | `string` | n/a     |   yes    |
| s3_bucket_name       | Name of the S3 bucket for state storage    | `string` | `null`  |    no    |
| lambda_timeout       | Lambda function timeout in seconds         | `number` | `300`   |    no    |
| lambda_memory        | Lambda function memory in MB               | `number` | `256`   |    no    |
| log_retention        | CloudWatch log retention in days           | `number` | `30`    |    no    |
| state_retention_days | Number of days to retain state files in S3 | `number` | `90`    |    no    |

## Outputs

| Name                  | Description                            |
|-----------------------|----------------------------------------|
| lambda_function_arn   | ARN of the Lambda function             |
| service_account_email | Email of the Scalr service account     |
| event_bridge_name     | Name of the EventBridge integration    |

## Module Structure

```
.
├── modules/
│   └── scalr-eventbridge/
│       ├── lambda/           # Lambda function and related resources
│       ├── eventbridge/      # EventBridge integration
│       ├── s3/              # S3 bucket and KMS resources
│       ├── main.tf          # Module orchestration
│       ├── variables.tf     # Module variables
│       ├── outputs.tf       # Module outputs
│       └── versions.tf      # Provider requirements
├── main.tf                  # Root module configuration
├── variables.tf            # Root variables
├── outputs.tf              # Root outputs
└── versions.tf             # Root provider requirements
```

## Security Considerations

- **Encryption**
  - All S3 objects are encrypted using KMS
  - Lambda environment variables are encrypted
  - Sensitive values are marked as such

- **Access Control**
  - IAM roles follow principle of least privilege
  - Service account has read-only access
  - S3 bucket policies are restrictive

- **Monitoring**
  - CloudWatch alarms for errors
  - X-Ray tracing enabled
  - Comprehensive logging

## Error Handling

- Automatic retries for failed events (3 attempts)
- Dead Letter Queue for unprocessable events
- CloudWatch alarms for error detection
- Comprehensive error logging

## Maintenance

- S3 bucket lifecycle policy for state file cleanup
- CloudWatch Logs retention policy
- Regular token rotation recommended
- KMS key rotation enabled

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License. See LICENSE for full details.