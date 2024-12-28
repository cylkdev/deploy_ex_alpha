
locals {
  inventory_group_snake_case = lower(
    replace(
      replace(
        replace(var.inventory_group, " ", "_"),
        "/[^a-zA-Z0-9_]/",
        ""
      ),
      "-",
      "_"
    )
  )
  inventory_group_kebab_case = lower(
    replace(
      replace(
        replace(var.inventory_group, " ", "-"), 
        "/[^a-zA-Z0-9-]/", ""
      ), 
      "_", "-"
    )
  )

  instance_group_snake_case = lower(
    replace(
      replace(
        replace(var.instance_group, " ", "_"),
        "/[^a-zA-Z0-9_]/",
        ""
      ),
      "-",
      "_"
    )
  )
  instance_group_kebab_case = lower(
    replace(
      replace(
        replace(var.instance_group, " ", "-"), 
        "/[^a-zA-Z0-9-]/", ""
      ), 
      "_", "-"
    )
  )
}

data "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_ids)

  id = var.public_subnet_ids[count.index]
}

resource "aws_lb_target_group" "ec2_lb_target_group" {
  count = var.enable_elb ? 1 : 0

  name = substr(format("%s-%s-%s", local.instance_group_kebab_case, var.environment, "lb-tg"), 0, 32)

  vpc_id = var.vpc_id
  protocol = "HTTP"
  port = var.elb_target_group_port

  tags = merge({
    Environment    = var.environment
    InstanceGroup  = local.instance_group_snake_case
    InventoryGroup = local.inventory_group_kebab_case
    Name           = format("%s-%s-%s", local.instance_group_kebab_case, var.environment, "lb-tg")
    Region         = var.region
    Vendor         = "Self"
    Type           = "Self Made"
  }, var.tags)
}

resource "aws_lb_target_group_attachment" "ec2_lb_target_group_attachment" {
  count = var.enable_elb && var.attach_target_group ? 1 : 0

  target_group_arn = aws_lb_target_group.ec2_lb_target_group[0].arn
  target_id        = var.target_id
  port             = var.elb_target_group_port
}

resource "aws_lb" "ec2_lb" {
  count = var.enable_elb ? 1 : 0

  name               = format("%s-%s-%s", local.instance_group_kebab_case, var.environment, "lb")
  load_balancer_type = "application"
  subnets            = [ for subnet in data.aws_subnet.public_subnet : subnet.id ]
  security_groups    = var.vpc_security_group_ids

  tags = merge({
    Environment    = var.environment
    InstanceGroup  = local.instance_group_snake_case
    InventoryGroup = local.inventory_group_kebab_case
    Name           = format("%s-%s-%s", local.instance_group_kebab_case, var.environment, "lb")
    Region         = var.region
    Vendor         = "Self"
    Type           = "Self Made"
  }, var.tags)
}

resource "aws_lb_listener" "ec2_lb_listener" {
  count = var.enable_elb ? 1 : 0 

  load_balancer_arn = aws_lb.ec2_lb[0].arn
  port = var.elb_listener_port
  protocol = aws_lb_target_group.ec2_lb_target_group[0].protocol

  default_action {
    type  = "forward"
    target_group_arn = aws_lb_target_group.ec2_lb_target_group[0].arn
  }
}