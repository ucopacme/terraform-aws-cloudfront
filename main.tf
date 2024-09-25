# Create an S3 bucket if the origin_type is set to "s3"
resource "aws_s3_bucket" "this" {
  count  = var.origin_type == "s3" ? 1 : 0
  bucket = var.s3_bucket_name
  tags   = var.tags
}

# Define a bucket policy for the S3 bucket if the origin_type is "s3"
resource "aws_s3_bucket_policy" "this" {
  count  = var.origin_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.this[0].id}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.s3[0].id}"
          }
        }
      }
    ]
  })
}

# Fetch the current AWS account ID
data "aws_caller_identity" "current" {}

# Create a CloudFront Origin Access Control (OAC) for the S3 bucket if the origin_type is "s3"
resource "aws_cloudfront_origin_access_control" "this" {
  count                            = var.origin_type == "s3" ? 1 : 0
  name                             = "${var.s3_bucket_name}-oac"
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

  origin {
    domain_name = aws_s3_bucket.this[0].bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.this[0].bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  price_class = var.price_class

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.this[0].bucket}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = var.compress
    cache_policy_id        = local.cache_policy_id
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    # Conditionally add the function_association if function_arn is provided
    dynamic "function_association" {
      for_each = var.function_arn != null && var.function_arn != "" ? [var.function_arn] : []
      content {
        event_type   = "viewer-request"
        function_arn = function_association.value
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
    geo_restriction {
      restriction_type = "none"
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

# Create a CloudFront distribution for the ALB origin if the origin_type is not "s3"
resource "aws_cloudfront_distribution" "alb" {
  count               = var.origin_type != "s3" ? 1 : 0
  enabled             = true
  default_root_object = var.default_root_object

  origin {
    domain_name = var.alb_arn
    origin_id   = "ALB-${var.alb_arn}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  price_class = var.price_class

  default_cache_behavior {
    target_origin_id       = "ALB-${var.alb_arn}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = local.cache_policy_id
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    cloudfront_default_certificate = var.acm_certificate_arn == "" ? true : false
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.minimum_protocol_version
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
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
