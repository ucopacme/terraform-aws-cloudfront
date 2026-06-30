# terraform-aws-cloudfront

Terraform module for creating AWS CloudFront distributions with S3, ALB, or VPC origin types.

## Features

- **S3 Origin** (`origin_type = "s3"`): Creates a CloudFront distribution with an S3 bucket origin (new or existing bucket) using Origin Access Control (OAC)
- **ALB Origin** (`origin_type = "alb"`): Creates a CloudFront distribution with a public Application Load Balancer custom origin
- **VPC Origin** (`origin_type = "vpc"`): Creates a CloudFront distribution with a VPC origin for private ALBs/NLBs that are not internet-facing

Additional capabilities across all origin types:
- Managed cache policies (CachingOptimized or CachingDisabled)
- CloudFront Functions (viewer-request)
- Lambda@Edge functions (viewer-request)
- Ordered cache behaviors with path-based routing
- Custom error responses
- Geo-restriction whitelisting
- Custom origin headers
- WAF Web ACL integration
- Origin request policies
- Response headers policies

## Usage

### S3 Origin

```hcl
module "cloudfront" {
  source          = "git::https://github.com/ucopacme/terraform-aws-cloudfront.git?ref=v0.0.12"
  origin_type     = "s3"
  s3_bucket_name  = "my-website-bucket"
  cache_policy_type = "cache-optimized"
  tags            = { Environment = "production" }
}
```

### ALB Origin (Public)

```hcl
module "cloudfront" {
  source                     = "git::https://github.com/ucopacme/terraform-aws-cloudfront.git?ref=v0.0.12"
  origin_type                = "alb"
  origin_id                  = "my-alb-origin"
  origin_domain_name         = "my-alb-123456.us-west-2.elb.amazonaws.com"
  alb_origin_protocol_policy = "https-only"
  cache_policy_type          = "caching-disabled"
  tags                       = { Environment = "production" }
}
```

### VPC Origin (Private ALB/NLB)

Use this when your ALB/NLB is in a private subnet and not internet-facing. CloudFront connects directly to the load balancer through your VPC without requiring public accessibility.

```hcl
module "cloudfront" {
  source              = "git::https://github.com/ucopacme/terraform-aws-cloudfront.git?ref=v0.0.12"
  origin_type         = "vpc"
  vpc_origin_name     = "my-private-alb-origin"
  vpc_origin_arn      = "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-private-alb/abc123"
  origin_id           = "my-alb-origin"
  origin_domain_name  = "myapp.example.com"  # Must match the ALB's TLS certificate for SNI
  cache_policy_type   = "caching-disabled"
  allowed_methods     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]

  custom_headers = [
    {
      name  = "X-Origin-Verify"
      value = "my-secret-header-value"
    }
  ]

  ordered_cache_behaviors = [
    {
      path_pattern             = "/api/*"
      target_origin_id         = "my-alb-origin"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cache_policy_type        = "caching-disabled"
      viewer_protocol_policy   = "https-only"
      lambda_function_arns     = ["arn:aws:lambda:us-east-1:123456789012:function:my-edge-function:5"]
      lambda_include_body      = true
    }
  ]

  tags = { Environment = "development" }
}
```

#### VPC Origin Prerequisites

1. **AWS Provider version**: >= 5.82 (the `aws_cloudfront_vpc_origin` resource was introduced in this version)
2. **ALB Security Group**: Must allow inbound traffic from the CloudFront-managed ENI security group. When a VPC origin is created, AWS places ENIs in the ALB's subnets with an AWS-managed security group. Allow inbound 443 from that security group:
   ```hcl
   # Find the CloudFront ENI security group after VPC origin creation:
   # aws ec2 describe-network-interfaces --filters "Name=description,Values=*CloudFront*" \
   #   --query 'NetworkInterfaces[*].Groups[*].GroupId' --output text --region <your-region>

   resource "aws_security_group_rule" "allow_cloudfront_eni" {
     type                     = "ingress"
     from_port                = 443
     to_port                  = 443
     protocol                 = "tcp"
     security_group_id        = "<your-alb-security-group-id>"
     source_security_group_id = "<cloudfront-eni-security-group-id>"
     description              = "Allow HTTPS from CloudFront VPC Origin ENIs"
   }
   ```
3. **ALB ARN**: You must pass the full ARN of the ALB/NLB via `vpc_origin_arn`
4. **Origin Domain Name**: The `origin_domain_name` must resolve to the ALB and match the ALB's TLS certificate (CloudFront uses this as the SNI during the TLS handshake). Use a Route 53 alias that the certificate covers rather than the raw ALB DNS name.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.82 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.82 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_distribution.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_distribution.vpc_origin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_cloudfront_vpc_origin.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_vpc_origin) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudfront_cache_policy.cache_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_cache_policy.caching_disabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_s3_bucket.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The ARN of the custom SSL/TLS certificate for CloudFront | `string` | `""` | no |
| <a name="input_additional_origins"></a> [additional\_origins](#input\_additional\_origins) | List of additional custom origins (e.g., API Gateway) | `list(object)` | `[]` | no |
| <a name="input_alb_origin_protocol_policy"></a> [alb\_origin\_protocol\_policy](#input\_alb\_origin\_protocol\_policy) | The origin protocol policy for the ALB (http-only, https-only, match-viewer). Used with origin\_type = "alb" only. | `string` | `"http-only"` | no |
| <a name="input_allowed_methods"></a> [allowed\_methods](#input\_allowed\_methods) | Allowed HTTP methods for CloudFront | `list(string)` | `["GET", "HEAD"]` | no |
| <a name="input_alternate_domain_names"></a> [alternate\_domain\_names](#input\_alternate\_domain\_names) | List of alternate domain names (CNAMEs) | `list(string)` | `[]` | no |
| <a name="input_cache_policy_type"></a> [cache\_policy\_type](#input\_cache\_policy\_type) | Cache policy type: "cache-optimized" or "caching-disabled" | `string` | `"cache-optimized"` | no |
| <a name="input_cached_methods"></a> [cached\_methods](#input\_cached\_methods) | Cached HTTP methods for CloudFront | `list(string)` | `["GET", "HEAD"]` | no |
| <a name="input_cloudfront_comment"></a> [cloudfront\_comment](#input\_cloudfront\_comment) | Comment/description for the CloudFront distribution | `string` | `"Managed by Terraform"` | no |
| <a name="input_cloudfront_function_arns"></a> [cloudfront\_function\_arns](#input\_cloudfront\_function\_arns) | List of CloudFront Function ARNs to associate with the default cache behavior | `list(string)` | `[]` | no |
| <a name="input_compress"></a> [compress](#input\_compress) | Enable or disable compression | `bool` | `true` | no |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | Set to true to create a new S3 bucket, false to use existing | `bool` | `true` | no |
| <a name="input_custom_headers"></a> [custom\_headers](#input\_custom\_headers) | List of custom headers to send to the origin | `list(object({name=string, value=string}))` | `[]` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | The default root object for CloudFront | `string` | `"index.html"` | no |
| <a name="input_enable_csp"></a> [enable\_csp](#input\_enable\_csp) | Enable Content Security Policy via CloudFront Response Headers Policy | `bool` | `false` | no |
| <a name="input_error_pages"></a> [error\_pages](#input\_error\_pages) | Map of error codes to custom error response settings | `map(object)` | `null` | no |
| <a name="input_existing_s3_bucket_name"></a> [existing\_s3\_bucket\_name](#input\_existing\_s3\_bucket\_name) | The name of an existing S3 bucket to use as the CloudFront origin | `string` | `""` | no |
| <a name="input_geo_restrictions_whitelist"></a> [geo\_restrictions\_whitelist](#input\_geo\_restrictions\_whitelist) | List of country codes to whitelist | `list(string)` | `[]` | no |
| <a name="input_lambda_function_arns"></a> [lambda\_function\_arns](#input\_lambda\_function\_arns) | List of Lambda@Edge ARNs to associate with the default cache behavior | `list(string)` | `[]` | no |
| <a name="input_minimum_protocol_version"></a> [minimum\_protocol\_version](#input\_minimum\_protocol\_version) | TLS minimum protocol version for CloudFront | `string` | `"TLSv1.2_2021"` | no |
| <a name="input_ordered_cache_behaviors"></a> [ordered\_cache\_behaviors](#input\_ordered\_cache\_behaviors) | List of ordered cache behaviors for path-based routing | `list(object)` | `[]` | no |
| <a name="input_origin_domain_name"></a> [origin\_domain\_name](#input\_origin\_domain\_name) | The domain name of the origin (ALB/NLB DNS name or Route 53 alias). Used with origin\_type = "alb" or "vpc". For VPC origins, must match the ALB's TLS certificate. | `string` | `""` | no |
| <a name="input_origin_id"></a> [origin\_id](#input\_origin\_id) | The origin ID string used within the CloudFront distribution. Used with origin\_type = "alb" or "vpc". | `string` | `""` | no |
| <a name="input_origin_request_policy_id"></a> [origin\_request\_policy\_id](#input\_origin\_request\_policy\_id) | Existing CloudFront Origin Request Policy ID for the default cache behavior | `string` | `null` | no |
| <a name="input_origin_type"></a> [origin\_type](#input\_origin\_type) | The type of the origin: `s3`, `alb`, or `vpc` | `string` | `"s3"` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | Price class for this distribution | `string` | `"PriceClass_100"` | no |
| <a name="input_response_headers_policy_id"></a> [response\_headers\_policy\_id](#input\_response\_headers\_policy\_id) | Existing CloudFront Response Headers Policy ID | `string` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | The name of the S3 bucket (optional if using ALB as origin) | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_vpc_origin_arn"></a> [vpc\_origin\_arn](#input\_vpc\_origin\_arn) | ARN of the ALB/NLB to use as a VPC origin (required when origin\_type is vpc) | `string` | `""` | no |
| <a name="input_vpc_origin_http_port"></a> [vpc\_origin\_http\_port](#input\_vpc\_origin\_http\_port) | HTTP port for the VPC origin | `number` | `80` | no |
| <a name="input_vpc_origin_https_port"></a> [vpc\_origin\_https\_port](#input\_vpc\_origin\_https\_port) | HTTPS port for the VPC origin | `number` | `443` | no |
| <a name="input_vpc_origin_name"></a> [vpc\_origin\_name](#input\_vpc\_origin\_name) | Name for the CloudFront VPC origin endpoint configuration | `string` | `""` | no |
| <a name="input_vpc_origin_protocol_policy"></a> [vpc\_origin\_protocol\_policy](#input\_vpc\_origin\_protocol\_policy) | Origin protocol policy for VPC origin (http-only, https-only, match-viewer) | `string` | `"https-only"` | no |
| <a name="input_vpc_origin_ssl_protocols"></a> [vpc\_origin\_ssl\_protocols](#input\_vpc\_origin\_ssl\_protocols) | SSL/TLS protocols for VPC origin (valid values: SSLv3, TLSv1, TLSv1.1, TLSv1.2) | `list(string)` | `["TLSv1.2"]` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | WAF Web ACL ARN to associate with the CloudFront distribution | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_alb_domain_name"></a> [cloudfront\_alb\_domain\_name](#output\_cloudfront\_alb\_domain\_name) | The domain name of the CloudFront distribution for ALB or VPC origin |
| <a name="output_cloudfront_distribution_zone_id"></a> [cloudfront\_distribution\_zone\_id](#output\_cloudfront\_distribution\_zone\_id) | The CloudFront distribution ID |
| <a name="output_cloudfront_s3_domain_name"></a> [cloudfront\_s3\_domain\_name](#output\_cloudfront\_s3\_domain\_name) | The domain name of the CloudFront distribution for S3 |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | The name of the S3 bucket being used as the origin |
| <a name="output_vpc_origin_id"></a> [vpc\_origin\_id](#output\_vpc\_origin\_id) | The CloudFront VPC origin ID |
