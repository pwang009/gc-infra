provider "aws" {
  region = var.aws_region
}

locals {
  environment_name = var.env_name != null ? var.env_name : data.terraform_remote_state.ebs.outputs.beanstalk_env_name
  app_name         = var.app_name

  # Remote state and computed values
  cognito_user_pool_id      = data.terraform_remote_state.cognito.outputs.user_pool_id
  cognito_user_pool_arn     = data.terraform_remote_state.cognito.outputs.user_pool_arn
  cognito_app_client_id     = data.terraform_remote_state.cognito.outputs.app_client_id
  cognito_app_client_secret = data.terraform_remote_state.cognito.outputs.app_client_secret
  cognito_region            = var.cognito_region != null ? var.cognito_region : var.aws_region

  db_name    = coalesce(var.db_name, data.terraform_remote_state.db.outputs.database_name)
  db_user    = var.db_user
  db_url     = coalesce(var.db_url, try(data.terraform_remote_state.db.outputs.connection_endpoint, data.terraform_remote_state.db.outputs.cluster_endpoint))
  redis_host = data.terraform_remote_state.db.outputs.redis_endpoint
  redis_port = tostring(data.terraform_remote_state.db.outputs.redis_port)

  media_s3_bucket = coalesce(var.media_s3_bucket, try(data.terraform_remote_state.s3_media[0].outputs.bucket_name, null), "goodconnex-media-${var.environment}")
  media_s3_region = coalesce(var.media_s3_region, try(data.terraform_remote_state.s3_media[0].outputs.bucket_region, null), var.aws_region)

  log_cloudwatch_group  = var.log_cloudwatch_group != null ? var.log_cloudwatch_group : "/goodconnex/api/${var.environment}"
  log_cloudwatch_region = var.log_cloudwatch_region != null ? var.log_cloudwatch_region : var.aws_region

  # Complete map of environment properties matching gc-api-v2-dev structure
  env_properties = {
    AUTH_MODE                 = var.auth_mode
    COGNITO_USER_POOL_ID      = local.cognito_user_pool_id
    COGNITO_USER_POOL_ARN     = local.cognito_user_pool_arn
    COGNITO_APP_CLIENT_ID     = local.cognito_app_client_id
    COGNITO_APP_CLIENT_SECRET = local.cognito_app_client_secret
    COGNITO_REGION            = local.cognito_region
    CORS_ALLOW_ORIGINS        = var.cors_allow_origins
    DBNAME                    = local.db_name
    DBUSER                    = local.db_user
    DBPASSWORD                = var.db_password
    DBURL                     = local.db_url
    IMAGE_MODERATION          = var.image_moderation
    LOG_CLOUDWATCH_ENABLED    = var.log_cloudwatch_enabled
    LOG_CLOUDWATCH_GROUP      = local.log_cloudwatch_group
    LOG_CLOUDWATCH_REGION     = local.log_cloudwatch_region
    LOG_FORMAT                = var.log_format
    LOG_HTTP_BODIES           = var.log_http_bodies
    LOG_HTTP_BODY_MAX_BYTES   = var.log_http_body_max_bytes
    LOG_LEVEL                 = var.log_level
    MEDIA_BACKEND             = var.media_backend
    MEDIA_S3_BUCKET           = local.media_s3_bucket
    MEDIA_S3_REGION           = local.media_s3_region
    OTP_OWNER                 = var.otp_owner
    PORT                      = var.app_port
    PUSH_DELIVERY             = var.push_delivery
    PYTHONPATH                = var.python_path
    REDIS_HOST                = local.redis_host
    REDIS_PORT                = local.redis_port
    REVENUECAT_API_KEY        = var.revenuecat_api_key
    REVENUECAT_WEBHOOK_SECRET = var.revenuecat_webhook_secret
    SLOTS_DEV_GRANT           = var.slots_dev_grant
  }

  option_settings = [
    for k, v in local.env_properties : {
      Namespace  = "aws:elasticbeanstalk:application:environment"
      OptionName = k
      Value      = v
    }
  ]
}

# Ensure Application Log Group exists in CloudWatch
resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = local.log_cloudwatch_group
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-app-log-group"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Saved Elastic Beanstalk Configuration Template for declarative tracking
resource "aws_elastic_beanstalk_configuration_template" "ebs_config_template" {
  name                = "${local.environment_name}-config-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  application         = local.app_name
  solution_stack_name = "64bit Amazon Linux 2023 v4.13.2 running Python 3.12"

  dynamic "setting" {
    for_each = local.env_properties
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# Update the running Elastic Beanstalk environment with environment properties
resource "terraform_data" "update_ebs_environment_properties" {
  input = {
    env_name        = local.environment_name
    app_name        = local.app_name
    region          = var.aws_region
    option_settings = local.option_settings
    properties_hash = sha256(jsonencode(local.env_properties))
  }

  provisioner "local-exec" {
    command = <<-EOT
      tmpfile=$(mktemp)
      cat << 'EOF' > "$tmpfile"
      ${jsonencode(local.option_settings)}
      EOF
      aws elasticbeanstalk update-environment \
        --application-name "${local.app_name}" \
        --environment-name "${local.environment_name}" \
        --region "${var.aws_region}" \
        --option-settings file://"$tmpfile"
      rm -f "$tmpfile"
    EOT
  }
}
