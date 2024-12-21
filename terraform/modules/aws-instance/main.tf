# module: aws-instance
# version: 0.1.0

locals {
  instance_name_kebab_case = lower(replace(var.instance_name, " ", "-"))
  instance_name_snake_case = lower(replace(var.instance_name, " ", "_"))
}

################################################################
# EC2 Key Pair
################################################################
#
# The key pair is a combination of a public key and a private
# key that enables secure communication between a system and the
# EC2 instance over SSH.
#
#################################################################

# ---
#
# Creates a TLS private key.
#
# *** IMPORTANT ***
# Do not output this resource as it will save the result in
# plaintext to the terraform state which is a security risk.
resource "tls_private_key" "ssh_key" {
  count = var.create_key_pair && (var.key_pair_key_name == null) ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# ---
#
# Creates a tls private key.
#
# *** IMPORTANT ***
# Do not output this resource as it will save the result in
# plaintext to the terraform state which is a security risk.
resource "aws_key_pair" "key_pair" {
  count = var.create_key_pair && (var.key_pair_key_name == null) ? 1 : 0

  key_name   = "${local.instance_name_kebab_case}-key-pair"
  public_key = tls_private_key.ssh_key[0].public_key_openssh
}

# ---
#
# Saves the TLS private key to a file.
resource "local_file" "ssh_key" {
  count = var.create_key_pair && (var.key_pair_key_name == null) ? 1 : 0

  filename        = "../${path.root}/ssh/aws_instance/${aws_key_pair.key_pair[0].key_name}.pem"
  content         = tls_private_key.ssh_key[0].private_key_pem
  file_permission = 0400
}

################################################################
# IAM (Identity and Access Management)
################################################################
#
#
# *** IMPORTANT ***
# The metadata service is used to securely provide temporary
# credentials. Any changes to this section may disrupt other
# components. See the documentation below for information on
# the behavior.
#
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
data "aws_iam_policy_document" "trust_policy" {
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
resource "aws_iam_role" "instance_role" {
  # <instance_name>-<environment>-role
  name = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "role")

  assume_role_policy = data.aws_iam_policy_document.trust_policy.json

  tags = merge({
    # <instance_name>-<environment>-role
    Name          = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "role")
    InstanceGroup = local.instance_name_snake_case
    Group         = var.deployment_group
    Environment   = var.environment
    Vendor        = "Self"
    Type          = "Self Made"
  }, var.tags)
}

# ---
#
# Creates a IAM Instance Profile which the ec2 instance
# will use to automatically assume the IAM role at runtime.
resource "aws_iam_instance_profile" "instance_profile" {
  # *** IMPORTANT ***
  # The name attribute must always be unique. This means that even
  # if you have different role or path values, duplicating an
  # existing instance profile name will lead to an
  # EntityAlreadyExists error.
  name = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "profile")

  role = aws_iam_role.instance_role.name
}

# ---
#
# Creates a IAM policy document for the IAM role policy.
# These permissions define what the IAM role can do, as
# well as the actions and resources the role can access.
data "aws_iam_policy_document" "role_policy" {
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
#
# See the IAM policy document for the permissions.
resource "aws_iam_role_policy" "role_policy" {
  name = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "policy")
  role = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.role_policy.json
}

################################################################
# SUBNET
################################################################
#
# This module only retrieves details about existing subnets.
# This is done by parsing a list of objects exported from
# the module `vpc-instance`.
#
# Keys
#
#   * availability_zone - Name of the availability zone.
#
#   * availability_zone_id - The id of `availability_zone`.
#
#   * cidr_block - An IPv4 CIDR block.
#
#   * id - The subnet id.
#
#   * ipv6_cidr_block - An IPv6 CIDR block.
#
################################################################

# ---
#
# Retrieves details for the subnet.
# 
# Note: This does not create the subnet resource. See the
# module `vpc-instance` for more information on creating
# subnets.
data "aws_subnet" "private_subnet" {
  for_each = var.available_private_subnets

  availability_zone = each.value.availability_zone
  id                = each.value.id
}

# ---
#
# Retrieves details for the subnet.
# 
# Note: This does not create the subnet resource. See the
# module `vpc-instance` for more information on creating
# subnets.
data "aws_subnet" "public_subnet" {
  for_each = var.available_public_subnets

  availability_zone = each.value.availability_zone
  id                = each.value.id
}

### EC2 INSTANCE

resource "terraform_data" "replace_triggered_by_data" {
  input = var.replace_triggered_by_data
}

resource "aws_instance" "ec2_instance" {
  count = var.desired_instance_count

  availability_zone           = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
  ami                         = var.instance_ami_id
  instance_type               = var.instance_type
  user_data                   = var.enable_user_data ? (var.user_data == null ? file("${path.module}/user_data.sh") : file(var.user_data)) : ""
  key_name                    = var.create_key_pair && (var.key_pair_key_name == null) ? aws_key_pair.key_pair[0].key_name : var.key_pair_key_name

  # The IAM instance profile is required to use the instance
  # metadata service. This profile is loaded at runtime with
  # the permissions defined by the IAM role.
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  vpc_security_group_ids = var.security_group_ids

  associate_public_ip_address = var.associate_public_ip_address

  # If `enable_public_instance` is `true` the instance is
  # placed in a public subnet, otherwise if `false` the
  # instance is placed in a private subnet and cannot be
  # accessed directly from the web.
  #
  # The instance cannot be accessed on the private subnet
  # because the route table does not include a route to
  # an Internet Gateway (IGW), which is required for
  # direct internet access.
  #
  # If the instance is on a private subnet and needs 
  # direct access to the internet consider using a
  # NAT Gateway or VPC endpoint.
  subnet_id = (var.enable_public_instance ?
    element(values(data.aws_subnet.public_subnet), count.index).id :
    element(values(data.aws_subnet.private_subnet), count.index).id
  )

  cpu_options {
    core_count       = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }

  private_dns_name_options {
    hostname_type                     = "resource-name"
    enable_resource_name_dns_a_record = var.enable_resource_name_dns_a_record
  }

  # Resources cannot be passed across modules which can affect
  # terraform's ability to detect changes that would require
  # another resource to be destroyed before the instance, for
  # example a security group.
  #
  # To allow resource changes to be tracked we use a terraform
  # data resource that accepts a list of values as strings.
  #
  # To use this you must define the change you wish to track
  # as a variable and pass that value to the resource as well
  # as the `replace_triggered_by_data` option of this module.
  lifecycle {
    replace_triggered_by = [ terraform_data.replace_triggered_by_data ]
  }

  tags = merge({
    AvailabilityZone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
    Environment      = var.environment
    Group            = var.deployment_group
    InstanceGroup    = local.instance_name_snake_case
    Name             = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, count.index)
    Region           = var.region
    Vendor           = "Self"
    Type             = "Self Made"
  }, var.tags)
}

### EBS VOLUME

resource "aws_ebs_volume" "ec2_ebs" {
  count = var.enable_ebs ? var.desired_instance_count : 0

  availability_zone  = var.availability_zone_names[count.index % length(var.availability_zone_names)]
  size               = var.instance_ebs_size

  tags = merge({
    AvailabilityZone = var.availability_zone_names[count.index % length(var.availability_zone_names)]
    Environment      = var.environment
    InstanceGroup    = local.instance_name_snake_case
    Group            = var.deployment_group
    Name             = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "ebs", count.index)
    Region           = var.region
    Vendor           = "Self"
    Type             = "Self Made"
  }, var.tags)
}

resource "aws_volume_attachment" "ec2_ebs_association" {
  count = var.enable_ebs ? var.desired_instance_count : 0

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ec2_ebs[count.index].id
  instance_id = aws_instance.ec2_instance[count.index].id
}

### ELASTIC IP

resource "aws_eip" "ec2_eip" {
  count = var.enable_eip ? var.desired_instance_count : 0

  domain = "vpc"

  tags = merge({
    Environment      = var.environment
    Group            = var.deployment_group
    InstanceGroup    = local.instance_name_snake_case
    Name             = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "eip", count.index)
    Region           = var.region
    Vendor           = "Self"
    Type             = "Self Made"
  }, var.tags)
}

resource "aws_eip_association" "ec2_eip_association" {
  count = var.enable_eip ? var.desired_instance_count : 0

  instance_id   = aws_instance.ec2_instance[count.index].id
  allocation_id = aws_eip.ec2_eip[count.index].id
}

# ### ELASTIC LOAD BALANCER

# resource "aws_lb_target_group" "ec2_lb_target_group" {
#   count = var.enable_elb && var.desired_instance_count > 1 ? 1 : 0

#   # The name is truncated because it cannot be longer than 32 characters.
#   name  = substr(format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "lb-tg"), 0, 32)

#   vpc_id             = var.vpc_id
#   protocol           = "HTTP"
#   port               = var.elb_target_group_port

#   tags = merge({
#     Environment      = var.environment
#     Group            = var.deployment_group
#     InstanceGroup    = local.instance_name_snake_case
#     Name             = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "lb-tg")
#     Region           = var.region
#     Vendor           = "Self"
#     Type             = "Self Made"
#   }, var.tags)
# }

# resource "aws_lb" "ec2_lb" {
#   count = var.enable_elb && var.desired_instance_count > 1 ? 1 : 0

#   name                = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "lb")
#   load_balancer_type  = "application"
#   subnets             = [ for subnet in data.aws_subnet.public_subnet : subnet.id ]
#   security_groups     = var.security_group_ids

#   tags = merge({
#     Environment   = var.environment
#     InstanceGroup = local.instance_name_snake_case
#     Group         = var.deployment_group
#     Name          = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "lb")
#     Region        = var.region
#     Vendor        = "Self"
#     Type          = "Self Made"
#   }, var.tags)
# }

# # Attach each ec2 instance to the target group
# resource "aws_lb_target_group_attachment" "ec2_lb_target_group_attachment" {
#   count = var.enable_elb ? var.desired_instance_count : 0

#   target_group_arn = aws_lb_target_group.ec2_lb_target_group[0].arn
#   target_id        = aws_instance.ec2_instance[count.index].id
#   port             = var.elb_target_group_port
# }

# LOAD BALANCER LISTENER
#
# A listener checks for connection requests using the configured protocol and port.
# Before you start using your load balancer you must add at least one listener.
# If your load balancer has no listeners, it can't receive incoming traffic.
#
# Listeners support the following protocols and ports:
#
# Protocols: HTTP, HTTPS
# Ports: 1-65535
#
# You can use an HTTPS listener to offload the work of encryption and decryption
# to your load balancer so that your applications can focus on their business
# logic. If the listener protocol is HTTPS, you must deploy at least one SSL
# server certificate on the listener.

# resource "aws_lb_listener" "ec2_lb_listener" {
#   count = var.enable_elb && var.desired_instance_count > 1 ? 1 : 0 

#   load_balancer_arn = aws_lb.ec2_lb[0].arn
#   port              = var.elb_listener_port
#   protocol          = aws_lb_target_group.ec2_lb_target_group[0].protocol

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ec2_lb_target_group[0].arn
#   }
# }

# ### Simple Queue Service

# resource "aws_sqs_queue" "ec2_sqs" {
#   count                     = (var.enable_sqs && var.desired_instance_count > 1) ? 1 : 0

#   name                      = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "sqs")
#   delay_seconds             = var.sqs_delay_seconds
#   max_message_size          = var.max_message_size
#   message_retention_seconds = var.message_retention_seconds
#   receive_wait_time_seconds = var.sqs_receive_wait_time_seconds

#   tags = merge({
#     Name          = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "sqs")
#     InstanceGroup = local.instance_name_snake_case
#     Group         = var.deployment_group
#     Environment   = var.environment
#     Vendor        = "Self"
#     Type          = "Self Made"
#   }, var.tags)
# }

# # Attach redrive policy for sqs queue
# resource "aws_sqs_queue_redrive_policy" "ec2_sqs_redrive" {
#   count                 = (var.enable_sqs && var.desired_instance_count > 1) ? 1 : 0

#   queue_url             = aws_sqs_queue.ec2_sqs[0].id

#   redrive_policy        = jsonencode({
#     deadLetterTargetArn = aws_sqs_queue.ec2_sqs_dlq[0].arn
#     maxReceiveCount     = 4
#   })
# }

# # Create SQS dead letter queue
# resource "aws_sqs_queue" "ec2_sqs_dlq" {
#   count = (var.enable_sqs && var.desired_instance_count > 1) ? 1 : 0

#   name = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "sqs-dlq")

#   redrive_allow_policy = jsonencode({
#     redrivePermission  = "byQueue",
#     sourceQueueArns    = [ aws_sqs_queue.ec2_sqs[0].arn ]
#   })
# }

# ### AUTO SCALING

# resource "aws_launch_template" "ec2_instance_template" {
#   count = (var.enable_auto_scaling && var.desired_instance_count > 1) ? 1 : 0

#   # <instance_name>-<environment>-lt
#   name_prefix   = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "lt")
#   image_id      = var.instance_ami_id
#   instance_type = var.instance_type
# }

# resource "aws_placement_group" "ec2_placement_group" {
#   count = (var.enable_auto_scaling && var.desired_instance_count > 1) ? length(var.availability_zone_names) : 0

#   # <instance_name>-<environment>-pg
#   name     = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "pg", count.index)
#   strategy = var.placement_group_strategy
# }

# resource "aws_autoscaling_group" "ec2_autoscaling_group" {
#   count = (var.enable_auto_scaling && var.desired_instance_count > 1) ? length(var.availability_zone_names) : 0
  
#   name                      = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "asg", count.index)
#   placement_group           = aws_placement_group.ec2_placement_group[count.index].id
#   desired_capacity          = var.desired_instance_count
#   min_size                  = var.minimum_instance_count
#   max_size                  = var.maximum_instance_count
#   health_check_grace_period = 300
#   health_check_type         = "ELB"
#   force_delete              = true

#   vpc_zone_identifier       = (
#     var.enable_public_instance ?
#     flatten([ for subnet in data.aws_subnet.public_subnet : subnet.availability_zone == element(var.availability_zone_names, count.index) ? [subnet.id] : [] ]) :
#     flatten([ for subnet in data.aws_subnet.private_subnet : subnet.availability_zone == element(var.availability_zone_names, count.index) ? [subnet.id] : [] ])
#   )

#   instance_maintenance_policy {
#     min_healthy_percentage = var.min_healthy_percentage
#     max_healthy_percentage = var.max_healthy_percentage
#   }

#   launch_template {
#     id      = aws_launch_template.ec2_instance_template[0].id
#     version = "$Latest"
#   }

#   initial_lifecycle_hook {
#     name                 = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "lck", count.index)
#     default_result       = "CONTINUE"
#     heartbeat_timeout    = 2000
#     lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

#     notification_metadata = jsonencode({
#       message = "EC2 Auto Scaling Test Message"
#       payload = merge({
#                   AvailabilityZone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
#                   Environment      = var.environment
#                   Group            = var.deployment_group
#                   InstanceGroup    = local.instance_name_snake_case
#                   Name             = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "asg", count.index)
#                   Region           = var.region
#                   Vendor           = "Self"
#                   Type             = "Self Made"
#                 }, var.tags)
#     })

#     notification_target_arn = aws_sqs_queue.ec2_sqs[0].arn
#     role_arn = aws_iam_role.instance_role.arn
#   }

#   timeouts {
#     delete = "15m"
#   }

#   dynamic "tag" {
#     for_each = merge({
#       AvailabilityZone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
#       Environment      = var.environment
#       Group            = var.deployment_group
#       InstanceGroup    = local.instance_name_snake_case
#       Name             = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "asg", count.index)
#       Region           = var.region
#       Vendor           = "Self"
#       Type             = "Self Made"
#     }, var.tags)

#     content {
#       key                 = tag.key
#       value               = tag.value
#       propagate_at_launch = true
#     }
#   }
# }