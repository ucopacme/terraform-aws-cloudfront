variable "s3_bucket_name" {
  description = "The name of the S3 bucket (optional if using ALB as origin)"
  type        = string
  default     = ""  # Default to empty if not provided
}

variable "function_arn" {
  description = "function_arn"
  type        = string
  default     = null  # Default to empty if not provided
}

variable "cloudfront_function_arns" {
  description = "List of CloudFront Function ARNs to associate"
  type        = list(string)
  default     = []
}

variable "lambda_function_arns" {
  description = "List of Lambda@Edge ARNs to associate"
  type        = list(string)
  default     = []
}

variable "minimum_protocol_version" {
  description = "TLS for CloudFront"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "acm_certificate_arn" {
  description = "The ARN of the custom SSL/TLS certificate for CloudFront"
  type        = string
  default     = ""
}

variable "allowed_methods" {
  description = "Allowed HTTP methods for CloudFront"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "compress" {
  description = "Enable or disable compress"
  type        = bool
  default     = true
}

variable "alternate_domain_names" {
  description = "List of alternate domain names (CNAMEs)"
  type        = list(string)
  default     = []
}

variable "cache_policy_type" {
  type    = string
  default = "cache-optimized" # Options can be "cache-optimized" or "caching-disabled"
}

variable "cached_methods" {
  description = "Cached HTTP methods for CloudFront"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "alb_origin_id" {
  description = "The origin ID for the ALB"
  type        = string
  default     = ""
}

variable "alb_domain_name" {
  description = "The dns name of the Application Load Balancer."
  type        = string
  default     = ""
}

variable "alb_origin_protocol_policy" {
  description = "The origin protocol policy for the ALB"
  type        = string
  default     = "http-only"
      // should be match viewer or https-only but was hardcoded to http-only, so in case 
      // backwards compatibility is needed, to keep the setting as is for older deploys
      // set default and this if not set to http-only, but have been setting https-only 
      // in ucop cf+alb deploys recently 
}

variable "origin_type" {
  description = "The type of the origin (s3 or alb)"
  type        = string
  default     = "s3"
}

variable "price_class" {
  description = "Price class for this distribution"
  type        = string
  default     = "PriceClass_100"
}

variable "default_root_object" {
  description = "The default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "geo_restrictions_whitelist" {
  description = "List of country codes to whitelist"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "error_pages" {
  description = "Map of error codes to custom error response settings"
  type = map(object({
    response_page_path    = string
    response_code         = number
    error_caching_min_ttl = number
  }))
  default = null
}

variable "create_s3_bucket" {
  description = "Set to true to create a new S3 bucket, false to use existing"
  type        = bool
  default     = true
}

variable "existing_s3_bucket_name" {
  description = "The name of an existing S3 bucket to use as the CloudFront origin"
  type        = string
  default     = ""
}


variable "enable_csp" {
  description = "Enable Content Security Policy via CloudFront Response Headers Policy"
  type        = bool
  default     = false
}

variable "csp_policy" {
  description = "Content Security Policy string"
  type        = string
  default     = "default-src 'self';"
}

variable "origin_request_policy_id" {
  description = "Existing CloudFront Origin Request Policy ID"
  type        = string
  default     = null
}

variable "response_headers_policy_id" {
  description = "Existing CloudFront Response Headers Policy ID"
  type        = string
  default     = null
}


variable "cloudfront_comment" {
  description = "Comment/description for the CloudFront distribution"
  type        = string
  default     = "Managed by Terraform"
}

variable "additional_origins" {
  description = "List of additional custom origins (e.g., API Gateway)"
  type = list(object({
    domain_name          = string
    origin_id            = string
    origin_path          = optional(string, "")
    origin_read_timeout  = optional(number, 60)
  }))
  default = []
}

variable "ordered_cache_behaviors" {
  description = "List of ordered cache behaviors for additional origins"
  type = list(object({
    path_pattern             = string
    target_origin_id         = string
    allowed_methods          = list(string)
    cached_methods           = optional(list(string), ["GET", "HEAD"])
    viewer_protocol_policy   = optional(string, "redirect-to-https")
    cache_policy_type        = optional(string, "caching-disabled")
    origin_request_policy_id = optional(string, null)
    lambda_function_arns     = optional(list(string), [])
    lambda_include_body      = optional(bool,"false")
  }))
  default = []
}

variable "web_acl_id" {
  description = "WAF Web ACL ARN to associate with the CloudFront distribution"
  type        = string
  default     = null
}

variable "custom_headers" {
  description = "List of custom headers"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
