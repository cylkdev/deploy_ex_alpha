# -----------------------------------------------------------------------------
# EC2 Instance Module
#
# Description: Provision AWS EC2 instances.
# Author: Kurt Hogarth <kurt@learn-elixir.dev>, Mika Kalathil <mika@learn-elixir.dev>
# Version: 0.1.0
# Last Updated: <LAST_UPDATED>
# -----------------------------------------------------------------------------

################################################################
# EC2 Key Pair
################################################################
#
# The key pair is a combination of a public key and a private
# key that enables secure communication between a system and
# the EC2 instance over SSH.

# ** IMPORTANT **
# Do not output this resource as it will save the result in
# plaintext to the terraform state which is a security risk.
resource "tls_private_key" "ssh_key" {
  count = var.create_key_pair ? 1 : 0

  algorithm = "RSA"
  rsa_bits = 4096
}

# ** IMPORTANT **
# Do not output this resource as it will save the result in
# plaintext to the terraform state which is a security risk.
resource "aws_key_pair" "key_pair" {
  count = var.create_key_pair ? 1 : 0

  key_name = "${var.instance_name}-key-pair"
  public_key = tls_private_key.ssh_key[0].public_key_openssh
}

resource "local_file" "ssh_key" {
  count = var.create_key_pair ? 1 : 0

  filename = "../${path.root}/terraform_exports/aws_instance/ec2-private-key.pem"
  content = tls_private_key.ssh_key[0].private_key_pem
  file_permission = 0400
}

################################################################
# SUBNET
################################################################

resource "aws_instance" "ec2_instance" {
  for_each = { for index in range(var.desired_count) : "${var.instance_name}-${var.network_group}-${index}" => index }

  ami               = var.instance_ami_id
  availability_zone = var.availability_zone_names[each.value % length(var.availability_zone_names)]
  instance_type     = var.instance_type

  # After attaching an Amazon EBS volume to an EC2 instance,
  # the disk needs to be prepared before it can be used. This is
  # done by the default `user_data.sh` file.
  user_data = (
    var.enable_user_data ?
    (
      var.user_data == null ?
      file("${path.module}/files/user_data.sh") :
      var.user_data
    ) :
    ""
  )

  key_name = var.key_pair_name == null ? (var.create_key_pair ? aws_key_pair.key_pair[0].key_name : null) : var.key_pair_name

  # The IAM instance profile is required to use the instance
  # metadata service. This profile is loaded at runtime with
  # the permissions defined by the IAM role.
  #
  # This functionality is utilized by other services to get
  # temporary credentials and changing this field may break
  # things.
  iam_instance_profile = var.instance_profile_name
  
  vpc_security_group_ids = var.vpc_security_group_ids

  associate_public_ip_address = var.associate_public_ip_address

  subnet_id = (
    var.enable_public_subnet ?
    element(
      lookup({ for subnet in var.public_subnets : subnet.availability_zone_name => subnet... }, var.availability_zone_names[each.value % length(var.availability_zone_names)]),
      each.value % length({ for subnet in var.public_subnets : subnet.availability_zone_name => subnet... })
    ).id
    :
    element(
      lookup({ for subnet in var.private_subnets : subnet.availability_zone_name => subnet... }, var.availability_zone_names[each.value % length(var.availability_zone_names)]),
      each.value % length({ for subnet in var.private_subnets : subnet.availability_zone_name => subnet... })
    ).id
  )

  cpu_options {
    core_count = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }

  private_dns_name_options {
    hostname_type = "resource-name"
    enable_resource_name_dns_a_record = var.enable_resource_name_dns_a_record
  }

  tags = merge({
    AvailabilityZone = var.availability_zone_names[each.value % length(var.availability_zone_names)]
    Environment      = var.environment
    Group            = var.inventory_group
    InstanceGroup    = var.instance_group
    Name             = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), each.value)
    NetworkGroup     = var.network_group
    Region           = var.region
    Type             = "Self Made"
    Vendor           = "Self"
  }, var.tags)
}

resource "aws_ebs_volume" "ec2_ebs" {
  for_each = (
    var.enable_ebs ?
    { for index in range(var.desired_count) : "${var.instance_name}-${var.network_group}-${index}" => index }
    :
    {}
  )

  availability_zone  = var.availability_zone_names[each.value % length(var.availability_zone_names)]
  size               = var.ebs_volume_size

  tags = merge({
    AvailabilityZone = var.availability_zone_names[each.value % length(var.availability_zone_names)]
    Environment      = var.environment
    Group            = var.inventory_group
    InstanceGroup    = var.instance_group
    Name             = format("%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), provider::corefunc::str_kebab(var.network_group), "ebs")
    NetworkGroup     = var.network_group
    Region           = var.region
    Type             = "Self Made"
    Vendor           = "Self"
  }, var.tags)
}

resource "aws_volume_attachment" "ec2_ebs_association" {
  for_each = (
    var.enable_ebs ?
    { for index in range(var.desired_count) : "${var.instance_name}-${var.network_group}-${index}" => index }
    :
    {}
  )

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ec2_ebs[each.key].id
  instance_id = aws_instance.ec2_instance[each.key].id
}
 
### ELASTIC IP

resource "aws_eip" "ec2_eip" {
  for_each = var.enable_eip ? { for index in range(var.desired_count) : "${var.instance_name}-${var.network_group}-${index}" => index } : {}

  domain = "vpc"

  tags = merge({
    Environment   = var.environment
    Group         = var.inventory_group
    InstanceGroup = var.instance_group
    Name          = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "eip")
    NetworkGroup  = var.network_group
    Region        = var.region
    Type          = "Self Made"
    Vendor        = "Self"
  }, var.tags)
}

resource "aws_eip_association" "ec2_eip_association" {
  for_each = var.enable_eip ? { for index in range(var.desired_count) : "${var.instance_name}-${var.network_group}-${index}" => index } : {}

  instance_id = aws_instance.ec2_instance[each.key].id
  allocation_id = aws_eip.ec2_eip[each.key].id
}

resource "aws_lb_target_group" "ec2_lb_target_group" {
  count = var.enable_load_balancer ? 1 : 0

  name = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "alb-tg")

  vpc_id   = var.vpc_id
  protocol = "HTTP"
  port     = var.target_group_port

  tags = merge({
    Environment   = var.environment
    InstanceGroup = var.instance_group
    Group         = var.inventory_group
    Name          = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "alb-tg")
    NetworkGroup  = var.network_group
    Region        = var.region
    Type          = "Self Made"
    Vendor        = "Self"
  }, var.tags)
}

resource "aws_lb_target_group_attachment" "ec2_lb_target_group_attachment" {
  for_each = var.enable_load_balancer ? { for index in range(var.desired_count) : "${var.instance_name}-${var.network_group}-${index}" => index } : {}

  target_group_arn = aws_lb_target_group.ec2_lb_target_group[0].arn
  target_id        = aws_instance.ec2_instance[each.key].id
  port             = var.target_group_port
}

resource "aws_lb" "load_balancer" {
  count = var.enable_load_balancer ? 1 : 0

  name = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "alb")
  load_balancer_type = "application"

  subnets = [ for subnet in var.public_subnets : subnet.id ]

  security_groups = var.vpc_security_group_ids

  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.ec2_lb_target_group,
      aws_lb_target_group_attachment.ec2_lb_target_group_attachment
    ]
  }

  tags = merge({
    Environment   = var.environment
    Group         = provider::corefunc::str_kebab(var.inventory_group)
    InstanceGroup = var.instance_group
    Name          = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "alb")
    NetworkGroup  = var.network_group
    Region        = var.region
    Type          = "Self Made"
    Vendor        = "Self"
  }, var.tags)
}

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
resource "aws_lb_listener" "ec2_lb_listener" {
  count = var.enable_load_balancer && var.enable_listener ? 1 : 0 

  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = var.listener_port
  protocol          = aws_lb_target_group.ec2_lb_target_group[0].protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_lb_target_group[0].arn
  }
}

# ### Simple Queue Service

# resource "aws_sqs_queue" "ec2_sqs" {
#   count                     = (var.enable_sqs && var.desired_count > 1) ? 1 : 0

#   name                      = format("%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "sqs")
#   delay_seconds             = var.sqs_delay_seconds
#   max_message_size          = var.max_message_size
#   message_retention_seconds = var.message_retention_seconds
#   receive_wait_time_seconds = var.sqs_receive_wait_time_seconds

#   tags = merge({
#     Environment   = var.environment
#     Group         = var.inventory_group
#     InstanceGroup = var.instance_group
#     Name          = format("%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "sqs")
#     Type          = "Self Made"
#     Vendor        = "Self"
#   }, var.tags)
# }

# # Attach redrive policy for sqs queue
# resource "aws_sqs_queue_redrive_policy" "ec2_sqs_redrive" {
#   count                 = (var.enable_sqs && var.desired_count > 1) ? 1 : 0

#   queue_url             = aws_sqs_queue.ec2_sqs[0].id

#   redrive_policy        = jsonencode({
#     deadLetterTargetArn = aws_sqs_queue.ec2_sqs_dlq[0].arn
#     maxReceiveCount     = 4
#   })
# }

# # Create SQS dead letter queue
# resource "aws_sqs_queue" "ec2_sqs_dlq" {
#   count = (var.enable_sqs && var.desired_count > 1) ? 1 : 0

#   name = format("%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "sqs-dlq")

#   redrive_allow_policy = jsonencode({
#     redrivePermission  = "byQueue",
#     sourceQueueArns    = [ aws_sqs_queue.ec2_sqs[0].arn ]
#   })
# }

# ### AUTO SCALING

# resource "aws_launch_template" "ec2_instance_template" {
#   count = (var.enable_auto_scaling && var.desired_count > 1) ? 1 : 0

#   # <instance_group>-<environment>-lt
#   name_prefix   = format("%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "lt")
#   image_id      = var.instance_ami_id
#   instance_type = var.instance_type
# }

# resource "aws_placement_group" "ec2_placement_group" {
#   count = (var.enable_auto_scaling && var.desired_count > 1) ? length(var.availability_zone_name_names) : 0

#   # <instance_group>-<environment>-pg
#   name     = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "pg", count.index)
#   strategy = var.placement_group_strategy
# }

# resource "aws_autoscaling_group" "ec2_autoscaling_group" {
#   count = (var.enable_auto_scaling && var.desired_count > 1) ? length(var.availability_zone_name_names) : 0
  
#   name                      = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "asg", count.index)
#   placement_group           = aws_placement_group.ec2_placement_group[count.index].id
#   desired_capacity          = var.desired_count
#   min_size                  = var.minimum_instance_count
#   max_size                  = var.maximum_instance_count
#   health_check_grace_period = 300
#   health_check_type         = "ELB"
#   force_delete              = true

#   vpc_zone_identifier       = (
#     var.enable_public_subnet ?
#     flatten([ for subnet in data.aws_subnet.public_subnet : subnet.availability_zone == element(var.availability_zone_name_names, count.index) ? [subnet.id] : [] ]) :
#     flatten([ for subnet in data.aws_subnet.private_subnet : subnet.availability_zone == element(var.availability_zone_name_names, count.index) ? [subnet.id] : [] ])
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
#     name                 = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "lck", count.index)
#     default_result       = "CONTINUE"
#     heartbeat_timeout    = 2000
#     lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

#     notification_metadata = jsonencode({
#       message = "EC2 Auto Scaling Test Message"
#       payload = merge({
#                   AvailabilityZone = var.availability_zone_name
#                   Environment      = var.environment
#                   Group            = var.inventory_group
#                   InstanceGroup    = var.instance_group
#                   Name             = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "asg", count.index)
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
#       AvailabilityZone = var.availability_zone_name
#       Environment      = var.environment
#       Group            = var.inventory_group
#       InstanceGroup    = var.instance_group
#       Name             = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.instance_name), var.environment, "asg", count.index)
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