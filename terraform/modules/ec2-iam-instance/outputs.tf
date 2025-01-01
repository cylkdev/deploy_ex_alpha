output "trust_policy_document" {
  value = data.aws_iam_policy_document.trust_policy_document
}

output "ec2_iam_role" {
  value = aws_iam_role.ec2_iam_role
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