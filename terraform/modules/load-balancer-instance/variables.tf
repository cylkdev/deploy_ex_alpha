
variable "environment" {
  type = string
  nullable = false
}

variable "inventory_group" {
  type = string
  nullable = false
  description = "Ansible inventory group name."
}

variable "tags" {
  type = map(string)
  nullable = false
  default  = {}
}

variable "enable_load_balancer" {
  type = bool
  nullable = false
  default = true
}

variable "load_balancer_name" {
  type = string
  nullable = false
}

variable "vpc_id" {
  type = string
  nullable = false
}

variable "public_subnet_ids" {
  type = list(string)
  nullable = false
}

variable "security_group_ids" {
  type = list(string)
  nullable = false
  description = <<EOF
  The list of security group IDs to associate with the instance.
  This defines the firewall rules for things like HTTP/HTTPS
  and SSH traffic.
  EOF
}

variable "instance_group_name" {
  type = string
  nullable = false
}

variable "target_ip" {
  type = string
  nullable = false
}

variable "target_group_port" {
  type        = number
  nullable    = false
  default     = 443
  description = "The port on which the load balancer should forward traffic to the targets (e.g. ec2 instances) that are registered in the target group."
}

variable "enable_listener" {
  type        = bool
  nullable    = false
  default     = true
}

variable "listener_port" {
  type        = number
  nullable    = false
  default     = 443
  description = "The port that the load balancer will listen on for incoming traffic."
}


