
################################################################
# IAM (Identity and Access Management)
################################################################
#
# > *** IMPORTANT ***
# > The metadata service is used to securely provide temporary
# > credentials. Any changes to this section may disrupt other
# > components. See the documentation below for information on
# > the behavior.
#
# An IAM role is a virtual identity that grants access to AWS
# resources. The role itself doesn’t define permissions and
# relies on IAM policies to define its behavior. These roles
# are required to obtain temporary security credentials via
# the metadata service.
#
# An instance profile is a container for an IAM role, allowing an
# EC2 instance to assume that role. When an instance profile is
# associated with an IAM role, the EC2 instance automatically
# assumes the role at runtime. Temporary credentials (access key,
# secret key, session token) are securely provided to the
# instance through the metadata service.
#
# The permissions available via temporary credentials are defined
# by IAM policies attached to the role. These permissions dictate
# actions the instance can perform, such as accessing S3 or
# DynamoDB.
#
# Temporary credentials are scoped to the IAM policies of the
# role, ensuring the instance can only execute explicitly
# allowed actions.
#
# IAM policies are like rules specifying allowed or denied
# actions for users, groups, or roles within your AWS account.
#
# Policies tell AWS:
#
#   * Who can access something.
#
#   * What they can do (e.g., read, write, delete).
#
#   * Where they can do it (specific resources like an S3 bucket
#     or EC2 instance).
#
#   * When or how they can do it (optional conditions).
#
# IAM role has the following policies:
#
#   * Trust policy - Define who/what can assume the role.
#
#   * Role policy - Specify actions, accessible resources, and
#     conditions.
#
#################################################################

# ---
#
# Creates a IAM policy document (Trust Policy) that defines
# who or what is allowed to assume the role
# (e.g EC2 instance / AWS Account).
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

# ---
#
# Creates a IAM role that defines the permissions available
# to the ec2 instance at runtime.
resource "aws_iam_role" "ec2_iam_role" {
  name = format("%s-%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.instance_group), provider::corefunc::str_kebab(var.environment), "role")
  assume_role_policy = data.aws_iam_policy_document.trust_policy_document.json

  tags = merge({
    Environment    = var.environment
    InstanceGroup  = var.instance_group
    Group          = var.vpc_group
    Name           = format("%s-%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.instance_group), provider::corefunc::str_kebab(var.environment), "role")
    NetworkGroup   = var.network_group
    Region         = var.region
    Type           = "Self Made"
    Vendor         = "Self"
  }, var.tags)
}

# ---
#
# Creates a IAM instance profile that the EC2 instance will
# assume on launch.
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  # The name attribute must always be unique. This means that even
  # if you have different role or path values, duplicating an
  # existing instance profile name will lead to an
  # EntityAlreadyExists error.
  name = format("%s-%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.instance_group), provider::corefunc::str_kebab(var.environment), "profile")
  role = aws_iam_role.ec2_iam_role.name
}

# ---
#
# Creates a IAM policy document for the IAM role policy.
# These permissions define what the IAM role can do, as
# well as the actions and resources the role can access.
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

# ---
#
# Creates a IAM role policy which defines what the role can do,
# as well as the actions and resources the role can access.
resource "aws_iam_role_policy" "role_policy" {
  name = format("%s-%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.instance_group), provider::corefunc::str_kebab(var.environment), "role_policy")

  role = aws_iam_role.ec2_iam_role.id

  policy = data.aws_iam_policy_document.role_policy_document.json
}