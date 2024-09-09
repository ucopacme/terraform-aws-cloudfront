output "cloudfront_s3_domain_name" {
  value = module.cloudfront.cloudfront_s3_domain_name

}

output "s3_bucket_name" {
  value = module.cloudfront.s3_bucket_name

}

output "cloudfront_distribution_zone_id" {
  value = module.cloudfront.cloudfront_distribution_zone_id

}

output "certificate_arn" {
  value = module.acm_certificate.certificate_arn
}



output "cloudfront_a_record_fqdn" {
  value       = aws_route53_record.cloudfront_alias.fqdn
  description = "The fully qualified domain name of the CloudFront A record."
}
