provider "aws" {
  region = "us-west-2"
}



module "cloudfront" {
  source                 = "git::https://git@github.com/ucopacme/terraform-aws-cloudfront.git"
  origin_type            = "s3"
  s3_bucket_name         = join("-", [local.environment, "app", "cdn", local.account_id, "us-west-2"])
  cache_policy_type      = local.cache_policy_type
  compress               = local.compress
  acm_certificate_arn    = local.acm_certificate_arn # Leave empty or not provide if origin_type is "s3"
  alternate_domain_names = local.alternate_domain_names
  allowed_methods        = local.allowed_methods
  error_pages = {
    "404" = {
      response_page_path    = "/error404.html"
      response_code         = 404
      error_caching_min_ttl = 1
    },
    "400" = {
      response_page_path    = "/error400.html"
      response_code         = 400
      error_caching_min_ttl = 1
    },
    "403" = {
      response_page_path    = "/error403.html"
      response_code         = 403
      error_caching_min_ttl = 1
    }
  }
  tags = {
    "ucop:application" = local.application
    "ucop:createdBy"   = local.createdBy
    "ucop:environment" = local.environment
    "ucop:group"       = local.group
    "ucop:source"      = local.source
  }
}


