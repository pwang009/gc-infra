data "archive_file" "define_challenge" {
  type        = "zip"
  source_file = "${path.module}/lambda/defineChallenge/index.js"
  output_path = "${path.module}/lambda/defineChallenge/defineChallenge.zip"
}

data "archive_file" "generate_otp" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/generateOTP"
  output_path = "${path.module}/lambda/generateOTP/generateOTP.zip"
}

data "archive_file" "validate_challenge" {
  type        = "zip"
  source_file = "${path.module}/lambda/validateChallenge/index.js"
  output_path = "${path.module}/lambda/validateChallenge/validateChallenge.zip"
}

resource "aws_iam_role" "lambda_cognito" {
  name = "${var.environment}-cognito-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.environment}-cognito-lambda-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_cognito.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sns" {
  name = "${var.environment}-cognito-lambda-sns"
  role = aws_iam_role.lambda_cognito.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

locals {
  lambdas = {
    defineChallenge   = { archive = data.archive_file.define_challenge,   handler = "index.handler" }
    generateOTP       = { archive = data.archive_file.generate_otp,       handler = "index.handler" }
    validateChallenge = { archive = data.archive_file.validate_challenge, handler = "index.handler" }
  }
}

resource "aws_lambda_function" "cognito_triggers" {
  for_each = local.lambdas

  function_name    = "${var.environment}-cognito-${each.key}"
  role             = aws_iam_role.lambda_cognito.arn
  handler          = each.value.handler
  runtime          = "nodejs24.x"
  filename         = each.value.archive.output_path
  source_code_hash = each.value.archive.output_base64sha256

  publish = true

  tags = {
    Name        = "${var.environment}-cognito-${each.key}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lambda_alias" "cognito_triggers" {
  for_each = aws_lambda_function.cognito_triggers

  name             = "latest"
  function_name    = each.value.function_name
  function_version = each.value.version
}

resource "aws_lambda_permission" "cognito_triggers" {
  for_each = aws_lambda_alias.cognito_triggers

  statement_id  = "AllowCognito"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "cognito-idp.amazonaws.com"
  qualifier     = each.value.name
  source_arn    = aws_cognito_user_pool.main.arn
}
