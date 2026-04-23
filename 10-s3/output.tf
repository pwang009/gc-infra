output "bucket_name" {
  description = "Name of the fileupload S3 bucket"
  value       = aws_s3_bucket.fileupload.id
}

output "bucket_arn" {
  description = "ARN of the fileupload S3 bucket"
  value       = aws_s3_bucket.fileupload.arn
}

output "bucket_region" {
  description = "Region of the fileupload S3 bucket"
  value       = aws_s3_bucket.fileupload.region
}
