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

  key_name = "${var.name}-key-pair"
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

locals {
  availability_zones_public_subnets = { for subnet in var.public_subnets : subnet.availability_zone => subnet... }
  availability_zones_private_subnets = { for subnet in var.private_subnets : subnet.availability_zone => subnet... }
}

locals {
  subnet_availability_zones = [ for i in range(var.desired_count) : var.availability_zones[i % length(var.availability_zones)] ]
}

locals {
  instances = {
    for i in range(var.desired_count) :
    "${var.vpc_group}-${var.network_group}-${var.instance_group}-${i}" => {
      index = i
      availability_zone = local.subnet_availability_zones[i]

      public_subnets = lookup(local.availability_zones_public_subnets, local.subnet_availability_zones[i])
      public_subnet  = element(
                        lookup(local.availability_zones_public_subnets, local.subnet_availability_zones[i]),
                        i % length(lookup(local.availability_zones_public_subnets, local.subnet_availability_zones[i]))
                      )

      private_subnets = lookup(local.availability_zones_private_subnets, local.subnet_availability_zones[i])
      private_subnet  = element(
                        lookup(local.availability_zones_private_subnets, local.subnet_availability_zones[i]),
                        i % length(lookup(local.availability_zones_private_subnets, local.subnet_availability_zones[i]))
                      )
    }
  }
}

resource "aws_instance" "ec2_instance" {
  for_each = local.instances

  ami               = var.ami
  availability_zone = each.value.availability_zone
  instance_type     = var.instance_type

  # After attaching an Amazon EBS volume to an EC2 instance,
  # the disk needs to be prepared before it can be used. This is
  # done by the default `user_data.sh` file.
  user_data_base64 = (
    var.enable_user_data ?
    (
      var.user_data == null ?
      filebase64("${path.module}/files/user_data.sh") :
      var.user_data
    ) :
    ""
  )

  key_name = (
    var.key_pair_name == null ?
    (var.create_key_pair ? aws_key_pair.key_pair[0].key_name : null)
    :
    var.key_pair_name
  )

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
  subnet_id = ( var.enable_public_subnet ? each.value.public_subnet.id : each.value.private_subnet.id )

  cpu_options {
    core_count = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }

  private_dns_name_options {
    hostname_type = "resource-name"
    enable_resource_name_dns_a_record = var.enable_resource_name_dns_a_record
  }

  tags = merge({
    Environment      = provider::corefunc::str_snake(var.environment)
    Group            = provider::corefunc::str_snake(var.vpc_group)
    InstanceGroup    = provider::corefunc::str_snake(var.instance_group)
    Name             = format(
                        "%s-%s-%s-%s-%s",
                        provider::corefunc::str_kebab(var.vpc_group),
                        provider::corefunc::str_kebab(var.network_group),
                        each.value.index,
                        provider::corefunc::str_kebab(var.name),
                        provider::corefunc::str_kebab(var.environment)
                      )
    NetworkGroup     = provider::corefunc::str_snake(var.network_group)
    Region           = provider::corefunc::str_snake(var.region)
    Type             = "Self Made"
    Vendor           = "Self"
  }, var.tags)
}

resource "aws_ebs_volume" "ec2_ebs" {
  for_each = var.enable_ebs ? local.instances : {}

  availability_zone  = each.value.availability_zone
  size               = var.ebs_volume_size

  tags = merge({
    Environment      = provider::corefunc::str_snake(var.environment)
    Group            = provider::corefunc::str_snake(var.vpc_group)
    InstanceGroup    = provider::corefunc::str_snake(var.instance_group)
    Name             = format(
                        "%s-%s-%s-%s-%s-%s",
                        provider::corefunc::str_kebab(var.vpc_group),
                        provider::corefunc::str_kebab(var.network_group),
                        provider::corefunc::str_kebab(var.name),
                        each.value.index,
                        provider::corefunc::str_kebab(var.environment),
                        "ebs"
                      )
    NetworkGroup     = provider::corefunc::str_snake(var.network_group)
    Region           = provider::corefunc::str_snake(var.region)
    Type             = "Self Made"
    Vendor           = "Self"
  }, var.tags)
}

resource "aws_volume_attachment" "ec2_ebs_association" {
  for_each = var.enable_ebs ? local.instances : {}

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ec2_ebs[each.key].id
  instance_id = aws_instance.ec2_instance[each.key].id
}
 
### ELASTIC IP

resource "aws_eip" "ec2_eip" {
  for_each = ( var.enable_eip ? local.instances : {} )

  domain = "vpc"

  tags = merge({
    Environment   = provider::corefunc::str_snake(var.environment)
    Group         = provider::corefunc::str_snake(var.vpc_group)
    InstanceGroup = provider::corefunc::str_snake(var.instance_group)
    Name          = format(
                      "%s-%s-%s",
                      provider::corefunc::str_snake(var.vpc_group),
                      provider::corefunc::str_snake(var.network_group),
                      provider::corefunc::str_snake(var.name),
                      each.value.index,
                      provider::corefunc::str_snake(var.environment),
                      "eip"
                    )
    NetworkGroup  = provider::corefunc::str_snake(var.network_group)
    Region        = provider::corefunc::str_snake(var.region)
    Type          = "Self Made"
    Vendor        = "Self"
  }, var.tags)
}

resource "aws_eip_association" "ec2_eip_association" {
  for_each = ( var.enable_eip ? local.instances : {} )

  instance_id = aws_instance.ec2_instance[each.key].id
  allocation_id = aws_eip.ec2_eip[each.key].id
}

locals {
  target_groups = (
    var.enable_target_group ?
    {
      for i in range(length(var.availability_zones)) :
        var.availability_zones[i] => {
          index = i
          availability_zone = var.availability_zones[i]
          name = format(
                  "%s-%s-%s-%s-%s",
                  provider::corefunc::str_kebab(var.vpc_group),
                  provider::corefunc::str_kebab(var.network_group),
                  provider::corefunc::str_kebab(var.name),
                  i,
                  provider::corefunc::str_kebab(var.environment)
                )
        }
    }
    :
    {}
  )
}

resource "aws_lb_target_group" "ec2_lb_target_group" {
  for_each = local.target_groups

  name = format("%s-%s", substr(each.value.name, 0, 32 - 7), "alb-tg")

  vpc_id   = var.vpc_id
  protocol = "HTTP"
  port     = var.target_group_port

  # Target groups are often referenced by other resources, such
  # as load balancer listeners, rules, or auto-scaling groups.
  # When a target group is destroyed before a new one is created,
  # any associated load balancer listeners or rules lose their
  # references, causing potential disruption in routing traffic.
  #
  # By setting create_before_destroy = true, Terraform creates
  # the new target group first and updates references to it
  # before destroying the old one, maintaining continuous
  # service availability.
  #
  # The new target group is provisioned and connected to the
  # load balancer before the old one is removed, allowing
  # for rolling updates.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge({
    Environment   = provider::corefunc::str_snake(var.environment)
    InstanceGroup = provider::corefunc::str_snake(var.instance_group)
    Group         = provider::corefunc::str_snake(var.vpc_group)
    Name          = format(
                      "%s-%s-%s-%s-%s-%s",
                      provider::corefunc::str_kebab(var.vpc_group),
                      provider::corefunc::str_kebab(var.network_group),
                      provider::corefunc::str_kebab(var.name),
                      each.value.index,
                      provider::corefunc::str_kebab(var.environment),
                      "alb-tg"
                    )
    NetworkGroup  = provider::corefunc::str_snake(var.network_group)
    Region        = provider::corefunc::str_snake(var.region)
    Type          = "Self Made"
    Vendor        = "Self"
  }, var.tags)
}

locals {
  load_balancers = (
    var.enable_load_balancer ?
    {
      for i in range(length(var.availability_zones)) :
        var.availability_zones[i] => {
          index = i

          name = format(
                  "%s-%s-%s-%s-%s",
                  provider::corefunc::str_kebab(var.vpc_group),
                  provider::corefunc::str_kebab(var.network_group),
                  provider::corefunc::str_kebab(var.name),
                  i,
                  provider::corefunc::str_kebab(var.environment)
                )

          availability_zone = var.availability_zones[i]

          public_subnets = flatten([
            for subnet in var.public_subnets :
            subnet.availability_zone == var.availability_zones[i] ? [subnet] : []
          ])
        }
    }
    :
    {}
  )
}

resource "aws_lb" "load_balancer" {
  for_each = local.load_balancers

  load_balancer_type = "application"

  name            = format("%s-%s", substr(each.value.name, 0, 32 - 4), "alb")
  subnets         = [ for subnet in each.value.public_subnets : subnet.id ]
  security_groups = var.vpc_security_group_ids

  tags = merge({
    Environment   = provider::corefunc::str_snake(var.environment)
    Group         = provider::corefunc::str_kebab(var.vpc_group)
    InstanceGroup = provider::corefunc::str_snake(var.instance_group)
    Name          = format(
                      "%s-%s-%s-%s-%s-%s",
                      provider::corefunc::str_kebab(var.vpc_group),
                      provider::corefunc::str_kebab(var.network_group),
                      provider::corefunc::str_kebab(var.name),
                      each.value.index,
                      provider::corefunc::str_kebab(var.environment),
                      "alb"
                    )
    NetworkGroup  = provider::corefunc::str_snake(var.network_group)
    Region        = provider::corefunc::str_snake(var.region)
    Type          = "Self Made"
    Vendor        = "Self"
  }, var.tags)
}

locals {
  target_group_attachments = (
    (var.enable_target_group && var.attach_target_group) ? 
    {
      for key, instance in local.instances :
      key => {
        instance = aws_instance.ec2_instance[key]
        target_group = aws_lb_target_group.ec2_lb_target_group[instance.availability_zone]
      }
    }
    :
    {}
  )
}

resource "aws_lb_target_group_attachment" "ec2_lb_target_group_attachment" {
  for_each = local.target_group_attachments

  target_group_arn = each.value.target_group.arn
  target_id        = each.value.instance.id
  port             = var.target_group_port
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
  for_each = (
    (var.enable_target_group && var.enable_listener) ?
    {
      for i in range(length(var.availability_zones)) : 
        var.availability_zones[i] => {
          index = i
          availability_zone = var.availability_zones[i]
          load_balancer = aws_lb.load_balancer[var.availability_zones[i]]
          target_group = aws_lb_target_group.ec2_lb_target_group[var.availability_zones[i]]
        }
    }
    :
    {}
  )

  load_balancer_arn = each.value.load_balancer.arn
  port              = var.listener_port
  protocol          = each.value.target_group.protocol

  # AWS requires that listeners have a defined action to process incoming requests.
  default_action {
    type             = "forward"
    target_group_arn = each.value.target_group.arn
  }
}

resource "aws_sqs_queue" "ec2_sqs" {
  count = var.enable_autoscaling ? 1 : 0

  name = format(
          "%s-%s-%s-%s-%s",
          provider::corefunc::str_kebab(var.vpc_group),
          provider::corefunc::str_kebab(var.network_group),
          provider::corefunc::str_kebab(var.name),
          provider::corefunc::str_kebab(var.environment),
          "sqs"
        )

  delay_seconds             = var.sqs_delay_seconds
  max_message_size          = var.sqs_max_message_size
  message_retention_seconds = var.sqs_message_retention_seconds
  receive_wait_time_seconds = var.sqs_receive_wait_time_seconds

  # Note: Ensure the visibility_timeout is greater than the average processing
  # time for messages but less than the `message_retention_seconds` to avoid
  # duplicate processing.
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds

  tags = merge({
    Environment   = provider::corefunc::str_snake(var.environment)
    Group         = provider::corefunc::str_snake(var.vpc_group)
    InstanceGroup = provider::corefunc::str_snake(var.instance_group)
    Name          = format(
                      "%s-%s-%s-%s-%s",
                      provider::corefunc::str_kebab(var.vpc_group),
                      provider::corefunc::str_kebab(var.network_group),
                      provider::corefunc::str_kebab(var.name),
                      provider::corefunc::str_kebab(var.environment),
                      "sqs"
                    )
    NetworkGroup  = provider::corefunc::str_snake(var.network_group)
    Type          = "Self Made"
    Vendor        = "Self"
  }, var.tags)
}

# Create a dead letter queue (DLQ) to handle messages that could
# not be processed after a specific number of retries.
resource "aws_sqs_queue" "ec2_sqs_dlq" {
  count = var.enable_autoscaling ? 1 : 0

  name = format(
          "%s-%s-%s-%s-%s",
          provider::corefunc::str_kebab(var.vpc_group),
          provider::corefunc::str_kebab(var.network_group),
          provider::corefunc::str_kebab(var.name),
          provider::corefunc::str_kebab(var.environment),
          "sqs_dlq"
        )

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns = [ aws_sqs_queue.ec2_sqs[0].arn ]
  })
}

resource "aws_sqs_queue_redrive_policy" "ec2_sqs_redrive" {
  count = var.enable_autoscaling ? 1 : 0

  queue_url = aws_sqs_queue.ec2_sqs[0].id

  redrive_policy        = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ec2_sqs_dlq[0].arn
    maxReceiveCount     = var.sqs_dlq_max_receive_count 
  })
}

resource "aws_placement_group" "ec2_placement_group" {
  # Each AZ has its own placement group, this ensures low-latency communication within the AZ.
  for_each = (
    var.enable_autoscaling ?
    {
      for i in range(length(var.availability_zones)) :
        var.availability_zones[i] => {
          index = i
          availability_zone = var.availability_zones[i]
        }
    }
    :
    {}
  )

  name = format(
    "%s-%s-%s-%s-%s-%s",
    provider::corefunc::str_kebab(var.vpc_group),
    provider::corefunc::str_kebab(var.network_group),
    provider::corefunc::str_kebab(var.name),
    each.value.index,
    provider::corefunc::str_kebab(var.environment),
    "pg"
  )

  strategy = var.placement_group_strategy
}

locals {
  launch_templates = (
    var.enable_autoscaling ?
    {
      for i in range(length(var.availability_zones)) :
        var.availability_zones[i] => {
          index = i
          availability_zone = var.availability_zones[i]
          placement_group = aws_placement_group.ec2_placement_group[var.availability_zones[i]]
        }
    }
    :
    {}
  )
}

resource "aws_launch_template" "ec2_instance_template" {
  for_each = local.launch_templates

  name_prefix = format(
    "%s-%s-%s-%s-%s-%s",
    provider::corefunc::str_kebab(var.vpc_group),
    provider::corefunc::str_kebab(var.network_group),
    provider::corefunc::str_kebab(var.name),
    each.value.index,
    provider::corefunc::str_kebab(var.environment),
    "tmpl"
  )

  image_id      = var.ami
  instance_type = var.instance_type

  ebs_optimized = true

  user_data = (
    var.enable_user_data ?
    (
      var.user_data == null ?
      filebase64("${path.module}/files/user_data.sh") :
      var.user_data
    ) :
    ""
  )

  vpc_security_group_ids = var.vpc_security_group_ids
  
  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = var.instance_profile_name
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = var.ebs_volume_size
    }
  }

  cpu_options {
    core_count       = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }

  placement {
    availability_zone = each.value.availability_zone
    group_name = each.value.placement_group.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      Environment      = provider::corefunc::str_snake(var.environment)
      Group            = provider::corefunc::str_snake(var.vpc_group)
      InstanceGroup    = provider::corefunc::str_snake(var.instance_group)
      Name             = format(
                          "%s-%s-%s-%s-%s-%s",
                          provider::corefunc::str_kebab(var.vpc_group),
                          provider::corefunc::str_kebab(var.network_group),
                          provider::corefunc::str_kebab(var.name),
                          each.value.index,
                          provider::corefunc::str_kebab(var.environment),
                          "tmpl"
                        )
      NetworkGroup     = provider::corefunc::str_snake(var.network_group)
      Region           = provider::corefunc::str_snake(var.region)
      Type             = "Self Made"
      Vendor           = "Self"
    }, var.tags)
  }
}

# - Each ASG scales independently within its AZ. This means if the desired
# capacity of both ASGs is 1, each ASG will maintain 1 instance, resulting
# in a total of 2 instances across both AZs.
#
# - If an ASG in us-west-1a scales up, only instances in that AZ are launched.
#
# - If an AZ becomes unavailable, the ASG in the other AZ will not automatically
# scale to handle the traffic from the failed AZ unless configured with a
# higher minimum or maximum size to compensate.
locals {
  autoscaling_groups = (
    var.enable_autoscaling ?
    {
      for i in range(length(var.availability_zones)) :
        var.availability_zones[i] => {
          index = i
          availability_zone = var.availability_zones[i]
          placement_group = aws_placement_group.ec2_placement_group[var.availability_zones[i]]
          launch_template = aws_launch_template.ec2_instance_template[var.availability_zones[i]]
          public_subnets = lookup(local.availability_zones_public_subnets, var.availability_zones[i])
          private_subnets = lookup(local.availability_zones_public_subnets, var.availability_zones[i])
        }
    }
    :
    {}
  )
}

resource "aws_autoscaling_group" "ec2_autoscaling_group" {
  for_each = local.autoscaling_groups
  
  name = format(
    "%s-%s-%s-%s-%s-%s",
    provider::corefunc::str_kebab(var.vpc_group),
    provider::corefunc::str_kebab(var.network_group),
    provider::corefunc::str_kebab(var.name),
    each.value.index,
    provider::corefunc::str_kebab(var.environment),
    "asg"
  )

  placement_group           = each.value.placement_group.id
  desired_capacity          = var.desired_count
  min_size                  = var.minimum_instance_count
  max_size                  = var.maximum_instance_count
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true

  # Specifies the subnets where the group can launch instances.
  # These subnets can be private or public. When launched in a
  # private subnet only outbound communication is allowed and
  # you must use a NAT Gateway or NAT Instance.
  vpc_zone_identifier = (
    var.enable_public_subnet ?
    [ for subnet in each.value.public_subnets : subnet.id ]
    :
    []
  )

  # List of policies to decide how the instances in the Auto Scaling Group should be terminated.
  termination_policies = [
    "OldestInstance",
    "OldestLaunchConfiguration",
  ]

  instance_maintenance_policy {
    min_healthy_percentage = var.min_healthy_percentage
    max_healthy_percentage = var.max_healthy_percentage
  }

  launch_template {
    id      = each.value.launch_template.id
    version = "$Latest"
  }

  initial_lifecycle_hook {
    name                 = format(
                            "%s-%s-%s-%s-%s-%s",
                            provider::corefunc::str_kebab(var.vpc_group),
                            provider::corefunc::str_kebab(var.network_group),
                            provider::corefunc::str_kebab(var.name),
                            each.value.index,
                            provider::corefunc::str_kebab(var.environment),
                            "lh_launching"
                          )
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = jsonencode({
      message = "[autoscaling] - EC2 Instance Launching"
      payload = merge({
        AvailabilityZone = each.value.availability_zone
        Environment      = provider::corefunc::str_snake(var.environment)
        Group            = provider::corefunc::str_snake(var.vpc_group)
        InstanceGroup    = provider::corefunc::str_snake(var.instance_group)
        NetworkGroup     = provider::corefunc::str_snake(var.network_group)
        Name             = provider::corefunc::str_kebab(var.name)
        Region           = provider::corefunc::str_snake(var.region)
      }, var.tags)
    })

    notification_target_arn = aws_sqs_queue.ec2_sqs[0].arn

    role_arn = var.iam_role_arn
  }

  initial_lifecycle_hook {
    name                 = format(
                            "%s-%s-%s-%s-%s-%s",
                            provider::corefunc::str_kebab(var.vpc_group),
                            provider::corefunc::str_kebab(var.network_group),
                            provider::corefunc::str_kebab(var.name),
                            each.value.index,
                            provider::corefunc::str_kebab(var.environment),
                            "lh_terminating"
                          )
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"

    notification_metadata = jsonencode({
      message = "[autoscaling] - EC2 Instance Terminating"
      payload = merge({
        AvailabilityZone = each.value.availability_zone
        Environment      = provider::corefunc::str_snake(var.environment)
        Group            = provider::corefunc::str_snake(var.vpc_group)
        InstanceGroup    = provider::corefunc::str_snake(var.instance_group)
        NetworkGroup     = provider::corefunc::str_snake(var.network_group)
        Name             = provider::corefunc::str_kebab(var.name)
        Region           = provider::corefunc::str_snake(var.region)
      }, var.tags)
    })

    notification_target_arn = aws_sqs_queue.ec2_sqs[0].arn

    role_arn = var.iam_role_arn
  }

  timeouts {
    delete = "15m"
  }

  dynamic "tag" {
    for_each = merge({
      Environment   = provider::corefunc::str_snake(var.environment)
      Group         = provider::corefunc::str_snake(var.vpc_group)
      InstanceGroup = provider::corefunc::str_snake(var.instance_group)
      Name          = format(
                      "%s-%s-%s-%s-%s-%s",
                      provider::corefunc::str_kebab(var.vpc_group),
                      provider::corefunc::str_kebab(var.network_group),
                      provider::corefunc::str_kebab(var.name),
                      each.value.index,
                      provider::corefunc::str_kebab(var.environment),
                      "asg"
                    )
      NetworkGroup  = provider::corefunc::str_snake(var.network_group)
      Region        = provider::corefunc::str_snake(var.region)
      Vendor        = "Self"
      Type          = "Self Made"
    }, var.tags)

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  autoscaling_group_attachments = (
    (var.enable_load_balancer && var.enable_target_group && var.enable_autoscaling) ?
    {
      for i in range(length(var.availability_zones)) :
      var.availability_zones[i] => {
        index = i
        availability_zone = var.availability_zones[i]
        autoscaling_group = aws_autoscaling_group.ec2_autoscaling_group[var.availability_zones[i]]
        target_group = aws_lb_target_group.ec2_lb_target_group[var.availability_zones[i]]
      }
    }
    :
    {}
  )
}
resource "aws_autoscaling_attachment" "ec2_autoscaling_group_attachment" {
  for_each = local.autoscaling_group_attachments

  autoscaling_group_name = each.value.autoscaling_group.name
  lb_target_group_arn    = each.value.target_group.arn
}