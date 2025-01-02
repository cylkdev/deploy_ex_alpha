
data "aws_iam_policy_document" "trust_policy_document" {
  statement {
    effect  = "Allow"
    actions = [
      # An entity with the role can use the AWS Security Token Service
      # to get a set of temporary security credentials that can be
      # used to access AWS resources. 
      "sts:AssumeRole"
    ]

    # These services can assume this role.
    principals {
      type        = "Service"
      identifiers = [
        "autoscaling.amazonaws.com",
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "role")
  assume_role_policy = data.aws_iam_policy_document.trust_policy_document.json

  tags = merge({
    Environment    = var.environment
    Group          = var.vpc_group
    Name           = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "role")
    Region         = var.region
    Type           = "Self Made"
    Vendor         = "Self"
  }, var.tags)
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  # The name attribute must always be unique. This means that even if
  # you have different role or path values, duplicating an existing
  # instance profile name will lead to an EntityAlreadyExists error.
  name = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "profile")
  role = aws_iam_role.ec2_iam_role.name
}

# 
data "aws_iam_policy_document" "role_policy_document" {
  statement {
    effect = "Allow"
    actions = ["autoscaling:*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["sns:*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["sqs:*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "role_policy" {
  name = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "role_policy")

  role = aws_iam_role.ec2_iam_role.id

  policy = data.aws_iam_policy_document.role_policy_document.json
}
