terraform {
  backend "s3" {
    # bucket set via: -backend-config="bucket=$BUCKET_NAME"
    # bucket         = "gc-terraform-state-c8f7ewhysy5w"
    # key set via: -backend-config="key=$ENV/$DIR/terraform.tfstate"
    # region set via: -backend-config="region=$REGION"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
