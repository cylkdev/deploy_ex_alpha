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

variable "instance_group" {
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

variable "replace_triggered_by" {
  type     = list(string)

  description = <<EOF
  Replaces the instance when any of the given values change.

  Note: Resources cannot be passed across modules which means
  you cannot track resources directly to detect changes that
  would require another resource to be destroyed before the
  instance.
  EOF
}

variable "associate_public_ip_address" {
  type = bool

  nullable = false

  default = true

  description = <<EOF
  When `true` the instance will be assigned a public IP
  address that can be used to communicate with the internet
  directly, otherwise if `false` the instance will only have
  a private IP address.
  EOF
}

variable "cpu_core_count" {
  type = number

  nullable = false

  default = 1

  description = <<EOF
  Sets the number of CPU cores for the instance.

  This option is only supported on creation of instance type
  that support CPU Options.
  EOF
}

variable "cpu_threads_per_core" {
  type     = number
  nullable = false
  default  = 2
}

variable "hostname_type" {
  type = string

  nullable = false

  default = "resource-name"

  description = <<EOF
  AWS EC2 instances are automatically assigned a Private DNS Name
  when they are launched. This private DNS name is used for
  internal communication within the same VPC or connected
  environments, such as peered VPCs, VPNs, or AWS Direct Connect. 

  When `hostname_type` is `resource-name` the private DNS name of
  the instance will include its resource name (instance ID) as
  part of the hostname.
   
  For example:
  
  ```
  <instance-id>.<region>.compute.internal
  ```
  
  When `hostname_type` is `ip-name` the private DNS name of the
  instance is based on the instance's private IP address.
   
  For example:
  
  ```
  ip-<private-ip-address>.<region>.compute.internal
  ```
  EOF
}

variable "enable_resource_name_dns_a_record" {
  type = bool

  nullable = false

  default = true

  description = <<EOF
  When `true` a DNS A record is created in your VPC's private
  DNS when an EC2 instance has the hostname type set to
  `resource-name` otherwise when `false` a DNS A record is
  not created.

  The DNS A record maps the domain name (e.g. <instance-id>.<region>.compute.internal)
  to the instance's private IP address.
  EOF
}

variable "desired_count" {
  type     = number

  nullable = false

  default = 1

  description = "The number of instances to launch."
}

variable "enable_user_data" {
  type = bool

  nullable = false

  default = false

  description = <<EOF
  When `true` and the `user_data` option is not set the
  default `user_data.sh` is used.

  When `true` and the `user_data` option is set the
  value of the option is used.

  When `false` the `user_data` is an empty string.
  EOF
}

variable "user_data" {
  type = string
  default = ""
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

variable "enable_public_subnet" {
  type     = bool

  nullable = false

  default  = true

  description = <<EOF
  When `true` the instance is placed in a public subnet,
  otherwise if `false` the instance is placed in a
  private subnet.

  Instances launched in a private subnet cannot be accessed
  directly from the web. A private subnet by definition is
  isolated from direct internet access and therefore does
  not have a route to an Internet Gateway (IGW), which is
  required for direct internet access.
  
  An Internet Gateway allows incoming and outgoing traffic.
  If the instance is on a private subnet and needs access
  to the internet consider using a NAT Gateway or VPC
  endpoint which only allows outgoing traffic to the web.

  A NAT Gateway is designed exclusively for outgoing traffic
  from private subnets to the internet while maintaining the
  privacy of the resources within those subnets. NAT Gateway
  replaces the private IP addresses of the instances in the
  private subnet with the NAT Gateway's Elastic IP when
  traffic goes out to the internet. No traffic can originate
  from the internet to instances in the private subnet via
  the NAT Gateway.

  Use Case: A database server in a private subnet fetching
  updates from a software repository on the internet.

  A VPC Endpoint allows private subnets to communicate with
  AWS services like S3. The method does not involve the
  internet at all and communication is restricted to
  specific AWS services over the AWS network.

  Use Case: A private subnet instance uploads files to S3
  using an S3 VPC endpoint.
  EOF
}

variable "available_public_subnets" {
  type = list(object({
    availability_zone    = string
    availability_zone_id = string
    cidr_block           = string
    id                   = string
    ipv6_cidr_block      = string
  }))

  nullable = false
}

variable "available_private_subnets" {
  type = list(object({
    availability_zone    = string
    availability_zone_id = string
    cidr_block           = string
    id                   = string
    ipv6_cidr_block      = string
  }))

  nullable = false
}

### SECURITY GROUP

variable "vpc_security_group_ids" {
  type = list(string)

  nullable = false

  default = []

  description = <<EOF
  The list of security group IDs to associate with the instance.
  This defines the firewall rules for things like HTTP/HTTPS
  and SSH traffic.
  EOF
}

### ELASTIC CLOUD BLOCK STORAGE

variable "enable_ebs" {
  description = "Enables instance to generate an elastic cloud block storage volume"
  type        = bool
  nullable    = false
  default     = false
}

variable "ebs_volume_size" {
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