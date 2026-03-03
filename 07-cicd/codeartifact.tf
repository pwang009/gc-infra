resource "aws_codeartifact_domain" "maven" {
  domain = "gc-maven-${var.environment}"
}

resource "aws_codeartifact_repository" "maven" {
  repository = "gc-maven-repo"
  domain     = aws_codeartifact_domain.maven.domain
}
