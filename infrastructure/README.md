# Mango Media Infrastructure

This directory contains the AWS CDK infrastructure code for the Mango Media website deployment.

## Architecture

- **S3 Bucket**: Private bucket for static website files
- **CloudFront Distribution**: Global CDN with custom domain and SSL
- **Route53**: DNS management for mangomedia.com
- **ACM Certificate**: SSL/TLS certificate for HTTPS
- **Origin Access Identity**: Secure access from CloudFront to S3

## Deployment

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Node.js 18+ installed
3. AWS CDK installed globally: `npm install -g aws-cdk`

### Manual Deployment

```bash
# Install dependencies
npm install

# Build the project
npm run build

# Bootstrap CDK (first time only)
npx cdk bootstrap

# Deploy the stack
npx cdk deploy
```

### Automated Deployment

The infrastructure is automatically deployed via GitHub Actions when changes are pushed to the main branch.

## Required GitHub Secrets

The GitHub Actions workflow requires these secrets:

- `AWS_ACCESS_KEY_ID`: AWS access key for deployment
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for deployment

## Outputs

After deployment, the stack provides:

- **BucketName**: S3 bucket name for the website
- **DistributionId**: CloudFront distribution ID
- **DistributionDomainName**: CloudFront domain name
- **WebsiteURL**: Final website URL (https://mangomedia.com)

## Domain Setup

1. The CDK stack will create a Route53 hosted zone for mangomedia.com
2. Update your domain registrar (GoDaddy) to use the Route53 nameservers
3. SSL certificate will be automatically validated via DNS

## CDK Commands

* `npm run build`   compile typescript to js
* `npm run watch`   watch for changes and compile
* `npm run test`    perform the jest unit tests
* `npx cdk deploy`  deploy this stack to your default AWS account/region
* `npx cdk diff`    compare deployed stack with current state
* `npx cdk synth`   emits the synthesized CloudFormation template

## Cost Estimation

- S3: ~$0.50/month for small website
- CloudFront: Free tier covers most small websites
- Route53: $0.50/month per hosted zone
- Certificate Manager: Free

Total estimated cost: ~$1/month for a small business website.
