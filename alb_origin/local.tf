data "aws_caller_identity" "current" {}

locals {
  application = ""
  environment = "dev"
  createdBy   = ""
  group       = ""
  source      = ""
  account_id  = data.aws_caller_identity.current.account_id

}



