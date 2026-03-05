resource "aws_codeartifact_domain" "maven" {
  domain = "gc-artifacts-domain"
}

resource "aws_codeartifact_repository" "maven" {
  repository = "gc-jar-repo"
  domain     = aws_codeartifact_domain.maven.domain
}
