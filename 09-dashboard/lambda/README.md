# Dashboard

## lambda 

### one-time manual login (Postman)
1a. Start phone login
POST /api/v1/auth/start-phone-login   
{ "phoneNumber": "+17776662345" }

1b. Confirm with OTP from SMS:
POST /api/v1/auth/confirm-phone-login   
{
  "phoneNumber": "+17776662345",
  "otpCode": "123456",
  "session": "<session from above>"
}

1c. Save the refreshToken to SSM:
```bash
aws ssm put-parameter \
  --name "/gc/lambda/refresh-token" \
  --value "<your_refresh_token>" \
  --type SecureString \
  --region us-west-1
  ```

## Lambda uses refresh token to get access token

## EventBridge schedule triggers the Lambda

## Key notes
1. Cognito refresh tokens expire after 30 days by default — you'll need to re-authenticate manually and update SSM when that happens (or extend the expiry in your Cognito User Pool settings)

2. The Lambda IAM role needs ssm:GetParameter and cognito-idp:InitiateAuth permissions

3. Store USER_POOL_CLIENT_ID in SSM or as a Lambda env var as well — don't hardcode it