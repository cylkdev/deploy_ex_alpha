data "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_ids)

  id = var.public_subnet_ids[count.index]
}

resource "aws_lb" "application_load_balancer" {
  count = var.enable_load_balancer ? 1 : 0

  name               = format("%s-%s-%s", provider::corefunc::str_kebab(var.load_balancer_name), var.environment, "lb")
  load_balancer_type = "application"
  subnets            = [ for subnet in data.aws_subnet.public_subnet : subnet.id ]
  security_groups    = var.security_group_ids

  tags = merge({
    Environment = var.environment
    Group       = provider::corefunc::str_kebab(var.inventory_group)
    Name        = format("%s-%s-%s", provider::corefunc::str_kebab(var.load_balancer_name), var.environment, "lb")
    Vendor      = "Self"
    Type        = "Self Made"
  }, var.tags)
}

resource "aws_lb_target_group" "lb_target_group" {
  count = var.enable_load_balancer ? 1 : 0

  name        = format("%s-%s-%s", provider::corefunc::str_kebab(var.instance_group_name), var.environment, "lb-tg")
  port        = var.target_group_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  tags = merge({
    Environment = var.environment
    Group       = provider::corefunc::str_kebab(var.inventory_group)
    Name        = format("%s-%s-%s", provider::corefunc::str_kebab(var.instance_group_name), var.environment, "lb-tg")
    Vendor      = "Self"
    Type        = "Self Made"
  }, var.tags)
}

resource "aws_lb_target_group_attachment" "lb_target_group_attachment" {
  count = var.enable_load_balancer ? 1 : 0

  target_group_arn = aws_lb_target_group.lb_target_group[0].arn
  target_id        = var.target_ip
  port             = var.target_group_port
}

# Note: can associate up to 5 target groups per listener rule to distribute the traffic.
resource "aws_lb_listener" "lb_target_group_listener" {
  count = var.enable_load_balancer && var.enable_listener ? 1 : 0

  load_balancer_arn = aws_lb.application_load_balancer[0].arn
  port              = var.listener_port
  protocol          = aws_lb_target_group.lb_target_group[0].protocol

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group[0].arn
  }
}