output "iam_user_deploy_access_key" {
  value = aws_iam_access_key.deploy.id
}
output "iam_user_deploy_encrypted_secret" {
  value = aws_iam_access_key.deploy.encrypted_secret
}
