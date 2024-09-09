provider "aws" {
  region = "us-west-2"
}



module "cloudfront" {
  source         = "git::https://git@github.com/ucopacme/terraform-aws-cloudfront.git"
  origin_type    = "alb"
  alb_arn        = "alb arn"
  tags = {
    "ucop:application" = local.application
    "ucop:createdBy"   = local.createdBy
    "ucop:environment" = local.environment
    "ucop:group"       = local.group
    "ucop:source"      = local.source
  }
}
