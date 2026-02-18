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

variable "alb_arn" {
  description = "The ARN of the Application Load Balancer."
  type        = string
  default     = ""
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
