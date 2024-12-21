### GENERAL

variable "environment" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "deployment_group" {
  type     = string
  nullable = false
}

variable "tags" {
  type     = map(string)
  nullable = false
  default  = {}
}

### AVAILABILITY ZONE

variable "availability_zone_names" {
  type     = list(string)
  nullable = false
}

### VPC

variable "vpc_id" {
  type     = string
  nullable = false
}

### EC2

variable "instance_name" {
  type     = string
  nullable = false
}

variable "instance_ami_id" {
  type = string
  nullable = false
  default = "ami-047d7c33f6e7b4bc4"
}

variable "instance_type" {
  type = string
  nullable = false
  default = "t3.micro"
}

variable "replace_triggered_by_data" {
  type     = list(string)
  nullable = false
}

variable "associate_public_ip_address" {
  type = bool
  nullable = false
  default = true
}

variable "cpu_core_count" {
  type     = number
  nullable = false
  default  = 1
}

variable "cpu_threads_per_core" {
  type     = number
  nullable = false
  default  = 2
}

variable "enable_resource_name_dns_a_record" {
  type = bool
  nullable = false
  default = true
}

variable "desired_instance_count" {
  type     = number
  nullable = false
  default = 1
}

variable "enable_user_data" {
  type = bool
  nullable = false
  default = false
}

variable "user_data" {
  type = string
}

### AUTO SCALING

variable "enable_auto_scaling" {
  description = "Enables instance to generate an elastic load balancer for itself"
  type        = bool
  nullable    = false
  default     = false
}

variable "maximum_instance_count" {
  type     = number
  nullable = false
  default  = 1
}

variable "minimum_instance_count" {
  type     = number
  nullable = false
  default  = 1
}

variable "placement_group_strategy" {
  description = "Placement group for EC2 instances"
  type        = string
  nullable    = false
  default     = "cluster"
}

variable "min_healthy_percentage" {
  type        = number
  nullable    = false
  default     = 90
}

variable "max_healthy_percentage" {
  type        = number
  nullable    = false
  default     = 120
}

### SUBNET

variable "enable_public_instance" {
  type     = bool
  nullable = false
  default  = true
}

variable "available_public_subnets" {
  type = map(object({
    availability_zone    = string
    availability_zone_id = string
    cidr_block           = string
    id                   = string
    ipv6_cidr_block      = string
  }))

  nullable = false
}

variable "available_private_subnets" {
  type = map(object({
    availability_zone    = string
    availability_zone_id = string
    cidr_block           = string
    id                   = string
    ipv6_cidr_block      = string
  }))

  nullable = false
}

### SECURITY GROUP

variable "security_group_ids" {
  type = list(string)
  nullable = false
  default = []
}

### ELASTIC CLOUD BLOCK STORAGE

variable "enable_ebs" {
  description = "Enables instance to generate an elastic cloud block storage volume"
  type        = bool
  nullable    = false
  default     = false
}

variable "instance_ebs_size" {
  description = "EBS size, default 16GB"
  type        = number
  nullable    = false
  default     = 16
}

### ELASTIC IP

variable "enable_eip" {
  description = "Enables instance to generate an elastic ip for itself"
  type        = bool
  nullable    = false
  default     = false
}

### ELASTIC LOAD BALANCER

variable "enable_elb" {
  description = "Enables instance to generate an elastic load balancer for itself"
  type        = bool
  nullable    = false
  default     = true
}

variable "elb_listener_port" {
  description = "The port that the load balancer will listen on for incoming traffic."
  type        = number
  nullable    = false
  default     = 80
}

variable "elb_target_group_port" {
  description = "The port on which the load balancer should forward traffic to the targets (e.g. ec2 instances) that are registered in the target group."
  type        = number
  nullable    = false
  default     = 80
}

### KEY PAIR

variable "create_key_pair" {
  description = "If true, a key pair is created; if false, it is not."
  type        = bool
  nullable    = false
  default     = true
}

variable "key_pair_key_name" {
  description = "Name of a EC2 key pair."
  type        = string
}

### Simple Queue Service

variable "enable_sqs" {
  description = "..."
  type        = bool
  nullable    = false
  default     = false
}

variable "sqs_delay_seconds" {
  description = "..."
  type = number
  nullable = false
  default = 90
}

variable "max_message_size" {
  description = "..."
  type = number
  nullable = false
  default = 2048
}

variable "message_retention_seconds" {
  description = "..."
  type = number
  nullable = false
  default = 86400
}

variable "sqs_receive_wait_time_seconds" {
  description = "..."
  type = number
  nullable = false
  default = 10
}