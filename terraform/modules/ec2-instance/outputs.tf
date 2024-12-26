output "trust_policy_document" {
  value = data.aws_iam_policy_document.trust_policy_document
}

output "ec2_instance_role" {
  value = aws_iam_role.ec2_instance_role
}

output "ec2_instance_profile" {
  value = aws_iam_instance_profile.ec2_instance_profile
}

output "role_policy_document" {
  value = data.aws_iam_policy_document.role_policy_document
}

output "role_policy" {
  value = aws_iam_role_policy.role_policy
}

output "private_subnet" {
  value = data.aws_subnet.private_subnet
}

output "public_subnet" {
  value = data.aws_subnet.public_subnet
}

output "replace_triggered_by" {
  value = terraform_data.replace_triggered_by
}

output "ec2_instance" {
  value = aws_instance.ec2_instance
}

output "ec2_ebs" {
  value = aws_ebs_volume.ec2_ebs
}

output "ec2_ebs_association" {
  value = aws_volume_attachment.ec2_ebs_association
}

output "ec2_eip" {
  value = aws_eip.ec2_eip
}

output "ec2_eip_association" {
  value = aws_eip_association.ec2_eip_association
}
