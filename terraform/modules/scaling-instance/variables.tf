variable "environment" {
  type = string
  nullable = false
}

variable "region" {
  type = string
  nullable = false
}

variable "tags" {
  type = map(string)
  nullable = false
  default  = {}
}

variable "inventory_group" {
  type = string
  nullable = false
  description = "The group this resource was deployed into."
}

variable "instance_group" {
  type = string
  nullable = false
  description = "Sets the `InstanceGroup` tag on the instance."
}

# ---

variable "public_subnet_ids" {
  type = list(string)
  nullable = false
}

variable "target_id" {
  type = string
  nullable = false
}

# ---

variable "vpc_id" {
  type = string
  nullable = false
  description = "VPC identifier."
}

variable "vpc_security_group_ids" {
  type = list(string)
  nullable = false
  description = <<EOF
  The list of security group IDs to associate with the instance.
  This defines the firewall rules for things like HTTP/HTTPS
  and SSH traffic.
  EOF
}

variable "enable_elb" {
  type        = bool
  nullable    = false
  default     = true
  description = "Enables instance to generate an elastic load balancer for itself"
}

variable "attach_target_group" {
  type        = bool
  nullable    = false
  default     = false
}

variable "elb_listener_port" {
  type        = number
  nullable    = false
  default     = 443
  description = "The port that the load balancer will listen on for incoming traffic."
}

variable "elb_target_group_port" {
  type        = number
  nullable    = false
  default     = 443
  description = "The port on which the load balancer should forward traffic to the targets (e.g. ec2 instances) that are registered in the target group."
}