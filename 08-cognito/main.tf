resource "aws_cognito_user_pool" "main" {
  name = "${var.environment}-user-pool"

  username_attributes = ["phone_number"]

  password_policy {
    minimum_length    = var.password_minimum_length
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  lambda_config {
    define_auth_challenge          = aws_lambda_alias.cognito_triggers["defineChallenge"].arn
    create_auth_challenge          = aws_lambda_alias.cognito_triggers["generateOTP"].arn
    verify_auth_challenge_response = aws_lambda_alias.cognito_triggers["validateChallenge"].arn
  }

  tags = {
    Name        = "${var.environment}-user-pool"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.environment}-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  generate_secret               = true
}

resource "aws_cognito_user_group" "users" {
  name         = "users"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Default group for newly signed-up users"
}
