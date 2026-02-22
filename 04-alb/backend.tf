
terraform {
    backend "s3" {
        # key is set via -backend-config in deploy.sh
        # dev: key = "dev/load-balancer/terraform.tfstate"
        # prod: key = "prod/load-balancer/terraform.tfstate"
    }
}
