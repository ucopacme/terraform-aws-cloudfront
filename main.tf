resource "aws_cloudfront_distribution" "s3" {
  count               = var.origin_type == "s3" ? 1 : 0
  enabled             = true
  default_root_object = var.default_root_object

  origin {
    domain_name = aws_s3_bucket.this[0].bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.this[0].bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.this[0].bucket}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = local.cache_policy_id
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
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

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.custom_certificate_arn == "" ? true : false
    acm_certificate_arn            = var.custom_certificate_arn != "" ? var.custom_certificate_arn : null
    ssl_support_method             = var.custom_certificate_arn != "" ? "sni-only" : null
  }
}
