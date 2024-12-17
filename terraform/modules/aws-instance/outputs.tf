### IAM

output "aws_iam_policy_document_ec2_trust_policy" {
  value = data.aws_iam_policy_document.ec2_trust_policy
}

output "aws_iam_role_ec2_instance_role" {
  value = aws_iam_role.ec2_instance_role
}

### SUBNETS

output "aws_subnet_private_subnet" {
  value = data.aws_subnet.private_subnet
}

output "aws_subnet_public_subnet" {
  value = data.aws_subnet.public_subnet
}

### EC2

output "terraform_data_instance_replacement_triggered_by" {
  value = terraform_data.instance_replacement_triggered_by
}

output "aws_instance_ec2_instance" {
  value = aws_instance.ec2_instance
}

### EBS

output "aws_ebs_volume_ec2_ebs" {
  value = aws_ebs_volume.ec2_ebs
}

output "aws_volume_attachment_ec2_ebs_association" {
  value = aws_volume_attachment.ec2_ebs_association
}

### ELASTIC IP

output "aws_eip_ec2_eip" {
  value = aws_eip.ec2_eip
}

output "aws_eip_association_ec2_eip_association" {
  value = aws_eip_association.ec2_eip_association
}

### ELASTIC LOAD BALANCER

output "aws_lb_target_group_ec2_lb_target_group" {
  value = aws_lb_target_group.ec2_lb_target_group
}

output "aws_lb_ec2_lb" {
  value = aws_lb.ec2_lb
}

output "aws_lb_target_group_attachment_ec2_lb_target_group_attachment" {
  value = aws_lb_target_group_attachment.ec2_lb_target_group_attachment
}

output "aws_lb_listener_ec2_lb_listener" {
  value = aws_lb_listener.ec2_lb_listener
}

### Simple Queue Service

output "aws_sqs_queue_ec2_sqs" {
  value = aws_sqs_queue.ec2_sqs
}

output "aws_sqs_queue_redrive_policy_ec2_sqs_redrive" {
  value = aws_sqs_queue_redrive_policy.ec2_sqs_redrive
}

output "aws_sqs_queue_ec2_sqs_dlq" {
  value = aws_sqs_queue.ec2_sqs_dlq
}

### AUTO SCALING

output "aws_launch_template_ec2_instance_template" {
  value = aws_launch_template.ec2_instance_template
}

output "aws_placement_group_ec2_placement_group" {
  value = aws_placement_group.ec2_placement_group
}

output "aws_autoscaling_group_ec2_autoscaling_group" {
  value = aws_autoscaling_group.ec2_autoscaling_group
}