# output "codeartifact_domain" {
#  value = aws_codeartifact_domain.maven.domain
# }

# output "codeartifact_repository" {
#  value = aws_codeartifact_repository.maven.repository
# }

output "github_user_access_key" {
  value = aws_iam_access_key.github_deployer.id
}

output "github_user_secret_key" {
  value     = aws_iam_access_key.github_deployer.secret
  sensitive = true
}
