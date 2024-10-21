# AWS IAM role used by Humanitec to provision resources

locals {
  admin_policy_arn   = "arn:aws:iam::aws:policy/AdministratorAccess"
  humanitec_user_arn = "arn:aws:iam::767398028804:user/humanitec"
}

resource "random_password" "external_id" {
  length  = 16
  special = false
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [local.humanitec_user_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [random_password.external_id.result]
    }
  }
}

resource "aws_iam_role" "humanitec_provisioner" {
  name = var.name

  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "humanitec_provisioner" {
  role       = aws_iam_role.humanitec_provisioner.name
  policy_arn = local.admin_policy_arn
}

resource "humanitec_resource_account" "humanitec_provisioner" {
  id   = var.name
  name = var.name
  type = "aws-role"
  credentials = jsonencode({
    aws_role    = aws_iam_role.humanitec_provisioner.arn
    external_id = random_password.external_id.result
  })

  depends_on = [
    # Otherwise the account looses permissions before the resources are deleted
    aws_iam_role_policy_attachment.humanitec_provisioner
  ]
}

# Example application and resource definition criteria

resource "humanitec_application" "app" {
  id   = var.name
  name = var.name
}

module "mysql" {
  source = "../../../humanitec-resource-defs/mysql/basic"

  resource_packs_aws_url = var.resource_packs_aws_url
  resource_packs_aws_rev = var.resource_packs_aws_rev
  append_logs_to_error   = true
  driver_account         = humanitec_resource_account.humanitec_provisioner.id

  region = var.region

  prefix        = var.prefix
  name          = var.name
  database_name = "my_database"
  username      = "username"
  password      = "password"

  create_db_subnet_group = true
  subnet_ids             = var.subnet_ids

  vpc_security_group_ids = [aws_security_group.mysql.id]
}

resource "humanitec_resource_definition_criteria" "mysql" {
  resource_definition_id = module.mysql.id
  app_id                 = humanitec_application.app.id

  force_delete = true
}

resource "aws_security_group" "mysql" {
  name        = "mysql"
  description = "mysql"
  vpc_id      = var.vpc_id
}

# resource "aws_vpc_security_group_ingress_rule" "k8s_node_mysql" {
#   security_group_id = aws_security_group.mysql.id

#   referenced_security_group_id = var.k8s_node_security_group_id
#   from_port                    = 3306
#   ip_protocol                  = "tcp"
#   to_port                      = 3306
# }
