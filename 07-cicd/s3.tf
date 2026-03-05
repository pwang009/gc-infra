resource "aws_s3_bucket" "artifacts" {
  bucket = "gc-app-deployments-c8f7ewhysy5a"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}
