output "iam_user_deploy_access_key" {
  value = aws_iam_access_key.deploy.id
}
output "iam_user_deploy_encrypted_secret" {
  value = aws_iam_access_key.deploy.encrypted_secret
}
output "iam_user_terraform_access_key" {
  value = aws_iam_access_key.terraform.id
}
output "iam_user_terraform_encrypted_secret" {
  value = aws_iam_access_key.terraform.encrypted_secret
}
output route53_zone_portfolio_name_servers {
  value = aws_route53_zone.portfolio.name_servers
}