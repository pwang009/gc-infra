# Certificate Instructions

## GET A CUSTOM DOMAIN CERTIFICATE
### send the request
```bash
aws acm request-certificate --domain-name api.lishanteala.com --validation-method DNS --region us-west-1
```

### changes in godaddy.com
- add a CNAME
- name: _d7efe80df29caba041d7b0cc5868ec6e.api.lishanteala.com.
- value: _49a39449d0c1f66ff9800b12059f323a.jkddzztszm.acm-validations.aws.

in godaddy, it will display _d7efe80df29caba041d7b0cc5868ec6e.api as name

### changes added to environment.tf file
- associate certificate to alb
- port forwarding from 80 to 443
- run terraform apply

## certificate reattachment

To test the certificate reattachment, you can simulate removing it from the ALB via AWS CLI, then use Terraform to refresh the state and reapply. This will verify that Terraform correctly reattaches the certificate from the variable.

### Steps to Test:

1. **Get the ALB ARN and Listener ARN** (from AWS CLI):
   - Get the ALB ARN from Elastic Beanstalk and assign to variable:
     ```bash
     albName=gc-api-prod
     albARN=$(aws elasticbeanstalk describe-environment-resources --environment-name $albName --query 'EnvironmentResources.LoadBalancers[0].Name' --output text)
     listenerARN=$(aws elbv2 describe-listeners --load-balancer-arn $albARN --query 'Listeners[?Port==`443`].ListenerArn' --output text)
     ```

2. **Remove the certificate from the ALB listener via AWS CLI**:
   ```bash
   aws elbv2 modify-listener --listener-arn $listenerARN --certificates '[]'
   curl http://api.lishanteala.com/greeting?name=Tony
   curl https://api.lishanteala.com/greeting?name=Tony
   ```

3. **Refresh Terraform state** to detect the drift:
   ```bash
   terraform -chdir=03-ebs-v1 refresh -var-file=prod.tfvars
   ```
   (Use `dev.tfvars` if testing dev environment.)

4. **Apply Terraform** to reattach the certificate:
   ```bash
   terraform -chdir=03-ebs-v1 apply -var-file=prod.tfvars -auto-approve
   ```

After applying, check the ALB in the AWS console or via CLI to confirm the certificate is reattached. This tests that the variable-driven configuration works as expected. If issues arise, ensure the certificate ARN in your `.tfvars` file is valid and the certificate is issued.