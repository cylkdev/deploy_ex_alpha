locals {
  instance_name_kebab_case = lower(replace(var.instance_name, " ", "-"))
  instance_name_snake_case = lower(replace(var.instance_name, " ", "_"))
}

# EC2 KEY PAIR
#
# A key pair can be created consisting of a public key and a private key
# which can be used to connect to an ec2 instance.

resource "tls_private_key" "key_pair" {
  count = var.create_key_pair && (var.key_pair_key_name == null) ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  count = var.create_key_pair && (var.key_pair_key_name == null) ? 1 : 0

  key_name   = "${var.instance_name}-key-pair"
  public_key = tls_private_key.key_pair[0].public_key_openssh
}

# The private key is saved at the root directory of this module.
resource "local_file" "ssh_key" {
  count = var.create_key_pair && (var.key_pair_key_name == null) ? 1 : 0

  filename        = "${path.root}/${aws_key_pair.key_pair[0].key_name}.pem"
  content         = tls_private_key.key_pair[0].private_key_pem
  file_permission = 0400
}

### IAM

data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "autoscaling.amazonaws.com",
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  # <instance_name>-<environment>-role
  name = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "role")

  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json

  tags = merge({
    # <instance_name>-<environment>-role
    Name          = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "role")
    InstanceGroup = local.instance_name_snake_case
    Group         = var.resource_group
    Environment   = var.environment
    Vendor        = "Self"
    Type          = "Self Made"
  }, var.tags)
}

data "aws_iam_policy_document" "ec2_permission" {
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

resource "aws_iam_role_policy" "ec2_permission" {
  name = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "policy")
  role = aws_iam_role.ec2_instance_role.id
  policy = data.aws_iam_policy_document.ec2_permission.json
}

### SUBNET

data "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_ids)

  id = element(var.private_subnet_ids, count.index)

  availability_zone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
}

data "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_ids)

  id = element(var.public_subnet_ids, count.index)
  
  availability_zone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
}

### EC2

resource "terraform_data" "instance_replacement_triggered_by" {
  input = var.instance_replacement_triggered_by
}

resource "aws_instance" "ec2_instance" {
  count = var.desired_instance_count

  availability_zone           = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
  ami                         = var.instance_ami_id
  instance_type               = var.instance_type
  user_data                   = var.enable_user_data ? (var.user_data == null ? file("${path.module}/user_data.sh") : file(var.user_data)) : ""
  key_name                    = var.create_key_pair && (var.key_pair_key_name == null) ? aws_key_pair.key_pair[0].key_name : var.key_pair_key_name

  subnet_id                   = var.enable_public_instance ? data.aws_subnet.public_subnet[count.index % length(var.public_subnet_ids)].id : data.aws_subnet.private_subnet[count.index % length(var.private_subnet_ids)].id
  vpc_security_group_ids      = var.security_group_ids

  associate_public_ip_address = var.associate_public_ip_address

  cpu_options {
    core_count       = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }

  private_dns_name_options {
    hostname_type                     = "resource-name"
    enable_resource_name_dns_a_record = var.enable_resource_name_dns_a_record
  }

  lifecycle {
    replace_triggered_by = [ terraform_data.instance_replacement_triggered_by ]
  }

  tags = merge({
    AvailabilityZone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
    Environment      = var.environment
    Group            = var.resource_group
    InstanceGroup    = local.instance_name_snake_case
    Name             = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, count.index)
    ProjectName      = var.project_name
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
    Group            = var.resource_group
    Name             = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "ebs", count.index)
    ProjectName      = var.project_name
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
    Group            = var.resource_group
    InstanceGroup    = local.instance_name_snake_case
    Name             = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "eip", count.index)
    ProjectName      = var.project_name
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
#     Group            = var.resource_group
#     InstanceGroup    = local.instance_name_snake_case
#     Name             = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "lb-tg")
#     ProjectName      = var.project_name
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
#     Group         = var.resource_group
#     Name          = format("%s-%s-%s", local.instance_name_kebab_case, var.environment, "lb")
#     ProjectName      = var.project_name
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
#     Group         = var.resource_group
#     Environment   = var.environment
#     ProjectName      = var.project_name
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
#                   Group            = var.resource_group
#                   InstanceGroup    = local.instance_name_snake_case
#                   Name             = format("%s-%s-%s-%s", local.instance_name_kebab_case, var.environment, "asg", count.index)
#                   Region           = var.region
#                   Vendor           = "Self"
#                   Type             = "Self Made"
#                 }, var.tags)
#     })

#     notification_target_arn = aws_sqs_queue.ec2_sqs[0].arn
#     role_arn = aws_iam_role.ec2_instance_role.arn
#   }

#   timeouts {
#     delete = "15m"
#   }

#   dynamic "tag" {
#     for_each = merge({
#       AvailabilityZone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
#       Environment      = var.environment
#       Group            = var.resource_group
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