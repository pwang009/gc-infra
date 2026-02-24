
terraform {
    backend "s3" {
        # key is set via -backend-config in deploy.sh
        # dev: key = "dev/app-ec2/terraform.tfstate"
        # prod: key = "prod/app-ec2/terraform.tfstate"
    }
}
