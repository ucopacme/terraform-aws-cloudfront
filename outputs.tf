# Existing resources...

output "s3_bucket_name" {
  description = "The name of the S3 bucket (only when origin_type is 's3')"
  value       = var.origin_type == "s3" ? aws_s3_bucket.this[0].bucket : null

}
# Output for CloudFront distribution (S3)
output "cloudfront_s3_domain_name" {
  value       = var.origin_type == "s3" && length(aws_cloudfront_distribution.s3) > 0 ? aws_cloudfront_distribution.s3[0].domain_name : null
  description = "The domain name of the CloudFront distribution for S3"
}

# Output for CloudFront distribution (ALB)
output "cloudfront_alb_domain_name" {
  value       = var.origin_type != "s3" && length(aws_cloudfront_distribution.alb) > 0 ? aws_cloudfront_distribution.alb[0].domain_name : null
  description = "The domain name of the CloudFront distribution for ALB"
}
