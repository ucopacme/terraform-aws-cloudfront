data "aws_caller_identity" "current" {}

locals {
  application            = ""
  environment            = ""
  createdBy              = ""
  group                  = ""
  source                 = ""
  account_id             = data.aws_caller_identity.current.account_id
  dev_zone_id            = ""
  cache_policy_type      = "caching-disabled"
  compress               = true
  acm_certificate_arn    = module.acm_certificate.certificate_arn
  alternate_domain_names = [""]
  allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]

}





