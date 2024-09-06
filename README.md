## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_distribution.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudfront_cache_policy.cache_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_cache_policy.caching_disabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_arn"></a> [alb\_arn](#input\_alb\_arn) | The ARN of the Application Load Balancer. | `string` | `""` | no |
| <a name="input_alb_origin_id"></a> [alb\_origin\_id](#input\_alb\_origin\_id) | The origin ID for the ALB | `string` | `""` | no |
| <a name="input_cache_policy_type"></a> [cache\_policy\_type](#input\_cache\_policy\_type) | n/a | `string` | `"cache-optimized"` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | The default root object for CloudFront | `string` | `"index.html"` | no |
| <a name="input_error_pages"></a> [error\_pages](#input\_error\_pages) | Map of error codes to custom error response settings | <pre>map(object({<br>    response_page_path    = string<br>    response_code         = number<br>    error_caching_min_ttl = number<br>  }))</pre> | `null` | no |
| <a name="input_origin_type"></a> [origin\_type](#input\_origin\_type) | The type of the origin (s3 or alb) | `string` | `"s3"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | The name of the S3 bucket (optional if using ALB as origin) | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_alb_domain_name"></a> [cloudfront\_alb\_domain\_name](#output\_cloudfront\_alb\_domain\_name) | The domain name of the CloudFront distribution for ALB |
| <a name="output_cloudfront_s3_domain_name"></a> [cloudfront\_s3\_domain\_name](#output\_cloudfront\_s3\_domain\_name) | The domain name of the CloudFront distribution for S3 |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | The name of the S3 bucket (only when origin\_type is 's3') |
