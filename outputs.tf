# Existing resources...

# output "s3_bucket_name" {
#   description = "The name of the S3 bucket (only when origin_type is 's3')"
#   value       = var.origin_type == "s3" ? aws_s3_bucket.this[0].bucket : null

# }
output "s3_bucket_name" {
  description = "The name of the S3 bucket being used as the origin"
  value       = local.final_s3_bucket_name
}

# Output for CloudFront distribution (S3)
output "cloudfront_s3_domain_name" {
  value       = var.origin_type == "s3" && length(aws_cloudfront_distribution.s3) > 0 ? aws_cloudfront_distribution.s3[0].domain_name : null
  description = "The domain name of the CloudFront distribution for S3"
}

# Output for CloudFront distribution (ALB)
output "cloudfront_alb_domain_name" {
  value = (
    var.origin_type == "vpc" && length(aws_cloudfront_distribution.vpc_origin) > 0
    ? aws_cloudfront_distribution.vpc_origin[0].domain_name
    : (var.origin_type == "alb" && length(aws_cloudfront_distribution.alb) > 0
      ? aws_cloudfront_distribution.alb[0].domain_name
      : null)
  )
  description = "The domain name of the CloudFront distribution for ALB or VPC origin"
}

# Output for CloudFront distribution ID
output "cloudfront_distribution_zone_id" {
  value = (
    var.origin_type == "vpc"
    ? aws_cloudfront_distribution.vpc_origin[0].id
    : (var.origin_type == "s3"
      ? aws_cloudfront_distribution.s3[0].id
      : aws_cloudfront_distribution.alb[0].id)
  )
  description = "The CloudFront distribution ID"
}

output "vpc_origin_id" {
  value       = var.origin_type == "vpc" ? aws_cloudfront_vpc_origin.this[0].id : null
  description = "The CloudFront VPC origin ID"
}

output "cloudfront_s3_arn" {
  description = "The ARN of the CloudFront distribution (S3 origin type)"
  value       = var.origin_type == "s3" && length(aws_cloudfront_distribution.s3) > 0 ? aws_cloudfront_distribution.s3[0].arn : null
}
