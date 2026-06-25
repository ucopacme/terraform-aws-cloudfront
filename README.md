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
| [aws_s3_bucket.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The ARN of the custom SSL/TLS certificate for CloudFront | `string` | `""` | no |
| <a name="input_additional_origins"></a> [additional\_origins](#input\_additional\_origins) | List of additional custom origins (e.g., API Gateway) | <pre>list(object({<br/>    domain_name          = string<br/>    origin_id            = string<br/>    origin_path          = optional(string, "")<br/>    origin_read_timeout  = optional(number, 60)<br/>  }))</pre> | `[]` | no |
| <a name="input_alb_domain_name"></a> [alb\_domain\_name](#input\_alb\_domain\_name) | The dns name of the Application Load Balancer. | `string` | `""` | no |
| <a name="input_alb_origin_id"></a> [alb\_origin\_id](#input\_alb\_origin\_id) | The origin ID for the ALB | `string` | `""` | no |
| <a name="input_alb_origin_protocol_policy"></a> [alb\_origin\_protocol\_policy](#input\_alb\_origin\_protocol\_policy) | The origin protocol policy for the ALB | `string` | `"http-only"` | no |
| <a name="input_allowed_methods"></a> [allowed\_methods](#input\_allowed\_methods) | Allowed HTTP methods for CloudFront | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD"<br/>]</pre> | no |
| <a name="input_alternate_domain_names"></a> [alternate\_domain\_names](#input\_alternate\_domain\_names) | List of alternate domain names (CNAMEs) | `list(string)` | `[]` | no |
| <a name="input_cache_policy_type"></a> [cache\_policy\_type](#input\_cache\_policy\_type) | n/a | `string` | `"cache-optimized"` | no |
| <a name="input_cached_methods"></a> [cached\_methods](#input\_cached\_methods) | Cached HTTP methods for CloudFront | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD"<br/>]</pre> | no |
| <a name="input_cloudfront_comment"></a> [cloudfront\_comment](#input\_cloudfront\_comment) | Comment/description for the CloudFront distribution | `string` | `"Managed by Terraform"` | no |
| <a name="input_cloudfront_function_arns"></a> [cloudfront\_function\_arns](#input\_cloudfront\_function\_arns) | List of CloudFront Function ARNs to associate | `list(string)` | `[]` | no |
| <a name="input_compress"></a> [compress](#input\_compress) | Enable or disable compress | `bool` | `true` | no |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | Set to true to create a new S3 bucket, false to use existing | `bool` | `true` | no |
| <a name="input_csp_policy"></a> [csp\_policy](#input\_csp\_policy) | Content Security Policy string | `string` | `"default-src 'self';"` | no |
| <a name="input_custom_headers"></a> [custom\_headers](#input\_custom\_headers) | List of custom headers | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | The default root object for CloudFront | `string` | `"index.html"` | no |
| <a name="input_enable_csp"></a> [enable\_csp](#input\_enable\_csp) | Enable Content Security Policy via CloudFront Response Headers Policy | `bool` | `false` | no |
| <a name="input_error_pages"></a> [error\_pages](#input\_error\_pages) | Map of error codes to custom error response settings | <pre>map(object({<br/>    response_page_path    = string<br/>    response_code         = number<br/>    error_caching_min_ttl = number<br/>  }))</pre> | `null` | no |
| <a name="input_existing_s3_bucket_name"></a> [existing\_s3\_bucket\_name](#input\_existing\_s3\_bucket\_name) | The name of an existing S3 bucket to use as the CloudFront origin | `string` | `""` | no |
| <a name="input_function_arn"></a> [function\_arn](#input\_function\_arn) | function\_arn | `string` | `null` | no |
| <a name="input_geo_restrictions_whitelist"></a> [geo\_restrictions\_whitelist](#input\_geo\_restrictions\_whitelist) | List of country codes to whitelist | `list(string)` | `[]` | no |
| <a name="input_lambda_function_arns"></a> [lambda\_function\_arns](#input\_lambda\_function\_arns) | List of Lambda@Edge ARNs to associate | `list(string)` | `[]` | no |
| <a name="input_minimum_protocol_version"></a> [minimum\_protocol\_version](#input\_minimum\_protocol\_version) | TLS for CloudFront | `string` | `"TLSv1.2_2021"` | no |
| <a name="input_ordered_cache_behaviors"></a> [ordered\_cache\_behaviors](#input\_ordered\_cache\_behaviors) | List of ordered cache behaviors for additional origins | <pre>list(object({<br/>    path_pattern             = string<br/>    target_origin_id         = string<br/>    allowed_methods          = list(string)<br/>    cached_methods           = optional(list(string), ["GET", "HEAD"])<br/>    viewer_protocol_policy   = optional(string, "redirect-to-https")<br/>    cache_policy_type        = optional(string, "caching-disabled")<br/>    origin_request_policy_id = optional(string, null)<br/>    lambda_function_arns     = optional(list(string), [])<br/>    lambda_include_body      = optional(bool,"false")<br/>  }))</pre> | `[]` | no |
| <a name="input_origin_request_policy_id"></a> [origin\_request\_policy\_id](#input\_origin\_request\_policy\_id) | Existing CloudFront Origin Request Policy ID | `string` | `null` | no |
| <a name="input_origin_type"></a> [origin\_type](#input\_origin\_type) | The type of the origin (s3 or alb) | `string` | `"s3"` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | Price class for this distribution | `string` | `"PriceClass_100"` | no |
| <a name="input_response_headers_policy_id"></a> [response\_headers\_policy\_id](#input\_response\_headers\_policy\_id) | Existing CloudFront Response Headers Policy ID | `string` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | The name of the S3 bucket (optional if using ALB as origin) | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | WAF Web ACL ARN to associate with the CloudFront distribution | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_alb_domain_name"></a> [cloudfront\_alb\_domain\_name](#output\_cloudfront\_alb\_domain\_name) | The domain name of the CloudFront distribution for ALB |
| <a name="output_cloudfront_distribution_zone_id"></a> [cloudfront\_distribution\_zone\_id](#output\_cloudfront\_distribution\_zone\_id) | The CloudFront distribution ID |
| <a name="output_cloudfront_s3_domain_name"></a> [cloudfront\_s3\_domain\_name](#output\_cloudfront\_s3\_domain\_name) | The domain name of the CloudFront distribution for S3 |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | The name of the S3 bucket being used as the origin |
