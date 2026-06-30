# Create an S3 bucket if the origin_type is set to "s3"
# Create bucket ONLY if origin is s3 AND create_s3_bucket is true
resource "aws_s3_bucket" "this" {
  count  = (var.origin_type == "s3" && var.create_s3_bucket) ? 1 : 0
  bucket = var.s3_bucket_name
  tags   = var.tags
}

# Fetch existing bucket details if we aren't creating one
# main.tf inside the module
data "aws_s3_bucket" "existing" {
  # Only run if origin is S3 AND the variable is actually a non-empty string
  count  = (var.origin_type == "s3" && var.existing_s3_bucket_name != null && var.existing_s3_bucket_name != "") ? 1 : 0
  bucket = var.existing_s3_bucket_name
}

locals {
  # Normalize bucket info so we can reference one variable throughout the rest of the code
  bucket_id          = var.create_s3_bucket ? try(aws_s3_bucket.this[0].id, "") : try(data.aws_s3_bucket.existing[0].id, "")
  bucket_domain_name = var.create_s3_bucket ? try(aws_s3_bucket.this[0].bucket_regional_domain_name, "") : try(data.aws_s3_bucket.existing[0].bucket_regional_domain_name, "")
}

# The policy will now ONLY be created if a NEW bucket is being created
resource "aws_s3_bucket_policy" "this" {
  count  = (var.origin_type == "s3" && var.create_s3_bucket) ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.this[0].id}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.s3[0].id}"
          }
        }
      },
      {
            "Sid": "AllowSSLRequestsOnly",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.this[0].id}/*",
                "arn:aws:s3:::${aws_s3_bucket.this[0].id}"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        },
    ],
    
  })
}

# Fetch the current AWS account ID
data "aws_caller_identity" "current" {}

# Create a CloudFront Origin Access Control (OAC) for the S3 bucket if the origin_type is "s3"
resource "aws_cloudfront_origin_access_control" "this" {
  count                            = var.origin_type == "s3" ? 1 : 0
  name                             = "${var.s3_bucket_name}${var.existing_s3_bucket_name}-oac"
  description                      = "OAC for S3 bucket ${var.s3_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                 = "always"
  signing_protocol                 = "sigv4"
}

# Create a CloudFront distribution for the S3 origin if the origin_type is "s3"
resource "aws_cloudfront_distribution" "s3" {
  count               = var.origin_type == "s3" ? 1 : 0
  enabled             = true
  default_root_object = var.default_root_object
  tags                = var.tags
  comment             = var.cloudfront_comment
  web_acl_id          = var.web_acl_id
  origin {
    domain_name = local.bucket_domain_name
    origin_id   = "S3-${local.bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  dynamic "origin" {
    for_each = var.additional_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      origin_path = origin.value.origin_path

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
        origin_read_timeout    = origin.value.origin_read_timeout
      }

      dynamic "custom_header" {
        for_each = var.custom_headers
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
    }
  }

  price_class = var.price_class

  default_cache_behavior {
    target_origin_id       = "S3-${local.bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = var.compress
    cache_policy_id        = local.cache_policy_id
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    response_headers_policy_id = var.response_headers_policy_id

    # Conditionally add the function_association if function_arn is provided
    # Dynamic block for CloudFront Functions
  dynamic "function_association" {
    for_each = var.cloudfront_function_arns != null && length(var.cloudfront_function_arns) > 0 ? var.cloudfront_function_arns : []
    content {
      event_type   = "viewer-request"
      function_arn = function_association.value
    }
  }

  # Dynamic block for Lambda@Edge Functions
  dynamic "lambda_function_association" {
    for_each = var.lambda_function_arns != null && length(var.lambda_function_arns) > 0 ? var.lambda_function_arns : []
    content {
      event_type = "viewer-request"
      lambda_arn = lambda_function_association.value
    }
  }

  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      cache_policy_id        = ordered_cache_behavior.value.cache_policy_type == "caching-disabled" ? data.aws_cloudfront_cache_policy.caching_disabled.id : data.aws_cloudfront_cache_policy.cache_optimized.id
      origin_request_policy_id = ordered_cache_behavior.value.origin_request_policy_id

      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_arns
        content {
          event_type = "viewer-request"
          lambda_arn = lambda_function_association.value
        }
      }
    }
  }

  aliases = var.alternate_domain_names

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.minimum_protocol_version
  }

  restrictions {
    dynamic "geo_restriction" {
      for_each = length(var.geo_restrictions_whitelist) > 0 ? [var.geo_restrictions_whitelist[0]] : []
      content {
        restriction_type = "whitelist"
        locations        = var.geo_restrictions_whitelist
      }
    }

    dynamic "geo_restriction" {
      for_each = length(var.geo_restrictions_whitelist) == 0 ? ["none"] : []
      content {
        restriction_type = "none"
      }
    }
  }

  # Dynamically create custom error responses if specified
  dynamic "custom_error_response" {
    for_each = var.error_pages != null ? var.error_pages : {}
    content {
      error_code            = custom_error_response.key
      response_page_path    = custom_error_response.value.response_page_path
      response_code         = custom_error_response.value.response_code
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }
}

# Create a CloudFront distribution for the ALB origin if the origin_type is "alb"
resource "aws_cloudfront_distribution" "alb" {
  count               = var.origin_type == "alb" ? 1 : 0
  enabled             = true
  default_root_object = var.default_root_object
  tags                = var.tags
  comment             = var.cloudfront_comment
  web_acl_id          = var.web_acl_id

  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id != "" ? var.origin_id : var.origin_domain_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.alb_origin_protocol_policy != "" ? var.alb_origin_protocol_policy : "http-only"
      // should be match viewer or https-only but was hardcoded to http-only, so in case 
      // backwards compatibility is needed, to keep the setting as is for older deploys
      // set default and this if not set to http-only, but have been setting https-only 
      // in ucop cf+alb deploys recently 
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    dynamic "custom_header" {
      for_each = var.custom_headers
      content {
        name  = custom_header.value.name
        value = custom_header.value.value
      }
    }

  }

  price_class = var.price_class

  default_cache_behavior {
    target_origin_id       = var.origin_id != "" ? var.origin_id : var.origin_domain_name
    viewer_protocol_policy = var.alb_origin_protocol_policy != "" ? var.alb_origin_protocol_policy : "redirect-to-https"
    compress               = var.compress
    cache_policy_id        = local.cache_policy_id
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    origin_request_policy_id = var.origin_request_policy_id
    response_headers_policy_id = var.response_headers_policy_id
    # Conditionally add the function_association if function_arn is provided
    # Dynamic block for CloudFront Functions
    dynamic "function_association" {
      for_each = var.cloudfront_function_arns != null && length(var.cloudfront_function_arns) > 0 ? var.cloudfront_function_arns : []
      content {
        event_type   = "viewer-request"
        function_arn = function_association.value
      }
    }

    # Dynamic block for Lambda@Edge Functions
    dynamic "lambda_function_association" {
      for_each = var.lambda_function_arns != null && length(var.lambda_function_arns) > 0 ? var.lambda_function_arns : []
      content {
        event_type = "viewer-request"
        lambda_arn = lambda_function_association.value
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      cache_policy_id        = ordered_cache_behavior.value.cache_policy_type == "caching-disabled" ? data.aws_cloudfront_cache_policy.caching_disabled.id : data.aws_cloudfront_cache_policy.cache_optimized.id
      origin_request_policy_id = ordered_cache_behavior.value.origin_request_policy_id

      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_arns
        content {
          event_type = "viewer-request"
          lambda_arn = lambda_function_association.value
          include_body = ordered_cache_behavior.value.lambda_include_body
        }
      }
    }
  }

  aliases = var.alternate_domain_names

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.minimum_protocol_version
  }

  restrictions {
    dynamic "geo_restriction" {
      for_each = length(var.geo_restrictions_whitelist) > 0 ? [var.geo_restrictions_whitelist[0]] : []
      content {
        restriction_type = "whitelist"
        locations        = var.geo_restrictions_whitelist
      }
    }

    dynamic "geo_restriction" {
      for_each = length(var.geo_restrictions_whitelist) == 0 ? ["none"] : []
      content {
        restriction_type = "none"
      }
    }
  }

  # Dynamically create custom error responses if specified
  dynamic "custom_error_response" {
    for_each = var.error_pages != null ? var.error_pages : {}
    content {
      error_code            = custom_error_response.key
      response_page_path    = custom_error_response.value.response_page_path
      response_code         = custom_error_response.value.response_code
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }
}

# =============================================================================
# CloudFront VPC Origin (created when origin_type is "vpc")
# =============================================================================
resource "aws_cloudfront_vpc_origin" "this" {
  count = var.origin_type == "vpc" ? 1 : 0

  vpc_origin_endpoint_config {
    name                   = var.vpc_origin_name
    arn                    = var.vpc_origin_arn
    http_port              = var.vpc_origin_http_port
    https_port             = var.vpc_origin_https_port
    origin_protocol_policy = var.vpc_origin_protocol_policy

    origin_ssl_protocols {
      items    = var.vpc_origin_ssl_protocols
      quantity = length(var.vpc_origin_ssl_protocols)
    }
  }

  tags = var.tags
}

# =============================================================================
# CloudFront Distribution with VPC Origin
# =============================================================================
resource "aws_cloudfront_distribution" "vpc_origin" {
  count               = var.origin_type == "vpc" ? 1 : 0
  enabled             = true
  default_root_object = var.default_root_object
  tags                = var.tags
  comment             = var.cloudfront_comment
  web_acl_id          = var.web_acl_id

  origin {
    domain_name = var.origin_domain_name # Required by schema, ignored at runtime for VPC origins
    origin_id   = var.origin_id != "" ? var.origin_id : var.origin_domain_name

    vpc_origin_config {
      vpc_origin_id = aws_cloudfront_vpc_origin.this[0].id
    }

    dynamic "custom_header" {
      for_each = var.custom_headers
      content {
        name  = custom_header.value.name
        value = custom_header.value.value
      }
    }
  }

  price_class = var.price_class

  default_cache_behavior {
    target_origin_id           = var.origin_id != "" ? var.origin_id : var.origin_domain_name
    viewer_protocol_policy     = "https-only"
    compress                   = var.compress
    cache_policy_id            = local.cache_policy_id
    allowed_methods            = var.allowed_methods
    cached_methods             = var.cached_methods
    origin_request_policy_id   = var.origin_request_policy_id
    response_headers_policy_id = var.response_headers_policy_id

    dynamic "function_association" {
      for_each = var.cloudfront_function_arns != null && length(var.cloudfront_function_arns) > 0 ? var.cloudfront_function_arns : []
      content {
        event_type   = "viewer-request"
        function_arn = function_association.value
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.lambda_function_arns != null && length(var.lambda_function_arns) > 0 ? var.lambda_function_arns : []
      content {
        event_type = "viewer-request"
        lambda_arn = lambda_function_association.value
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern             = ordered_cache_behavior.value.path_pattern
      target_origin_id         = ordered_cache_behavior.value.target_origin_id
      allowed_methods          = ordered_cache_behavior.value.allowed_methods
      cached_methods           = ordered_cache_behavior.value.cached_methods
      viewer_protocol_policy   = ordered_cache_behavior.value.viewer_protocol_policy
      cache_policy_id          = ordered_cache_behavior.value.cache_policy_type == "caching-disabled" ? data.aws_cloudfront_cache_policy.caching_disabled.id : data.aws_cloudfront_cache_policy.cache_optimized.id
      origin_request_policy_id = ordered_cache_behavior.value.origin_request_policy_id

      dynamic "lambda_function_association" {
        for_each = ordered_cache_behavior.value.lambda_function_arns
        content {
          event_type   = "viewer-request"
          lambda_arn   = lambda_function_association.value
          include_body = ordered_cache_behavior.value.lambda_include_body
        }
      }
    }
  }

  aliases = var.alternate_domain_names

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.minimum_protocol_version
  }

  restrictions {
    dynamic "geo_restriction" {
      for_each = length(var.geo_restrictions_whitelist) > 0 ? [var.geo_restrictions_whitelist[0]] : []
      content {
        restriction_type = "whitelist"
        locations        = var.geo_restrictions_whitelist
      }
    }

    dynamic "geo_restriction" {
      for_each = length(var.geo_restrictions_whitelist) == 0 ? ["none"] : []
      content {
        restriction_type = "none"
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.error_pages != null ? var.error_pages : {}
    content {
      error_code            = custom_error_response.key
      response_page_path    = custom_error_response.value.response_page_path
      response_code         = custom_error_response.value.response_code
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }
}
