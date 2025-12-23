data "aws_cloudfront_cache_policy" "cache_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

locals {
  cache_policy_id = (
    var.cache_policy_type == "cache-optimized" ?
    data.aws_cloudfront_cache_policy.cache_optimized.id :
    data.aws_cloudfront_cache_policy.caching_disabled.id
  )

  # 1. Check if S3 is actually being used
  is_s3 = var.origin_type == "s3"

  # 2. Check if an existing bucket name was provided
  has_existing = var.existing_s3_bucket_name != null && var.existing_s3_bucket_name != ""

  # 3. Determine the final name safely
  # We use try() to handle cases where the resource doesn't exist yet
  final_s3_bucket_name = local.is_s3 ? (local.has_existing ? var.existing_s3_bucket_name : try(aws_s3_bucket.this[0].id, "")) : null
}

