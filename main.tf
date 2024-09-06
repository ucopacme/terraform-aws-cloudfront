# Define an S3 bucket if the origin type is "s3"
resource "aws_s3_bucket" "this" {
  count  = var.origin_type == "s3" ? 1 : 0
  bucket = var.s3_bucket_name
  tags   = var.tags
}

# Define an S3 bucket policy to allow CloudFront to access the bucket
resource "aws_s3_bucket_policy" "this" {
  count = var.origin_type == "s3" ? 1 : 0
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

# Data source to get the current AWS account ID
data "aws_caller_identity" "current" {}

# Define CloudFront Origin Access Control (OAC) for S3 bucket
resource "aws_cloudfront_origin_access_control" "this" {
  count                            = var.origin_type == "s3" ? 1 : 0
  name                             = "${var.s3_bucket_name}-oac"
  description                      = "OAC for S3 bucket ${var.s3_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                 = "always"
  signing_protocol                 = "sigv4"
}

# Define CloudFront distribution for S3 origin
resource "aws_cloudfront_distribution" "s3" {
  count               = var.origin_type == "s3" ? 1 : 0
  enabled             = true
  default_root_object = var.default_root_object

  # Define the origin pointing to the S3 bucket
  origin {
    domain_name = aws_s3_bucket.this[0].bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.this[0].bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  # Define default cache behavior for the distribution
  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.this[0].bucket}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = local.cache_policy_id
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
  }

  # Configure custom error responses based on provided values
  dynamic "custom_error_response" {
    for_each = var.error_pages != null ? var.error_pages : {}
    content {
      error_code            = custom_error_response.key
      response_page_path    = custom_error_response.value.response_page_path
      response_code         = custom_error_response.value.response_code
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # No geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use default CloudFront certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Define CloudFront distribution for ALB origin
resource "aws_cloudfront_distribution" "alb" {
  count               = var.origin_type != "s3" ? 1 : 0
  enabled             = true
  default_root_object = var.default_root_object

  # Define the origin pointing to the ALB
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

  # Define default cache behavior for the distribution
  default_cache_behavior {
    target_origin_id       = "ALB-${var.alb_arn}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = local.cache_policy_id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
  }

  # Configure custom error responses based on provided values
  dynamic "custom_error_response" {
    for_each = var.error_pages != null ? var.error_pages : {}
    content {
      error_code            = custom_error_response.key
      response_page_path    = custom_error_response.value.response_page_path
      response_code         = custom_error_response.value.response_code
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # No geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use default CloudFront certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
