# X-Ray Configuration for GC API

This module sets up AWS X-Ray tracing for the Elastic Beanstalk Spring Boot application.

## Components

- **Sampling Rule**: Configures what percentage of requests to trace (10% for prod, 50% for dev)
- **X-Ray Group**: Organizes traces by service name for easier filtering
- **CloudWatch Log Group**: Stores X-Ray insights and anomalies
- **IAM Policy**: Grants EC2 instances permission to write traces to X-Ray

## Integration Steps

### 1. Deploy X-Ray Infrastructure

```bash
cd 06-x-ray
terraform init -backend-config="key=prod/x-ray/terraform.tfstate"
terraform apply -var-file=prod.tfvars
```

### 2. Update Beanstalk IAM Role

Attach the X-Ray write policy to the Beanstalk EC2 instance role:

```bash
# Get the policy ARN from Terraform output
XRAY_POLICY_ARN=$(terraform output -raw xray_policy_arn)

# Get the Beanstalk instance role name (from 03-ebs-v1 outputs or describe instances)
# Then attach the policy:
aws iam attach-role-policy \
  --role-name gc-api-prod-eb-ec2-role \
  --policy-arn $XRAY_POLICY_ARN
```

Or, add it via Terraform in 03-ebs-v1/iam.tf:
```terraform
resource "aws_iam_role_policy_attachment" "xray_access" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = data.terraform_remote_state.xray.outputs.xray_policy_arn
}
```

### 3. Add X-Ray SDK to Spring Boot Application

Update your `pom.xml` to include the AWS X-Ray SDK for Java:

```xml
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-xray-recorder-sdk-spring</artifactId>
    <version>2.14.1</version>
</dependency>
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-xray-recorder-sdk-aws-sdk-v2-instrumentor</artifactId>
    <version>2.14.1</version>
</dependency>
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-xray-recorder-sdk-sql-mysql</artifactId>
    <version>2.14.1</version>
</dependency>
```

### 4. Configure X-Ray in Spring Boot

Add to `application.yaml` or `application-prod.yaml`:

```yaml
aws:
  xray:
    enabled: true
    tracing_enabled: true
    context_missing_strategy: LOG_ERROR
    sampling_rate: 0.1  # Match the Terraform sampling_rate
    daemon_addr: 127.0.0.1:2000
```

Or set via Beanstalk environment variable:

```bash
aws elasticbeanstalk update-environment \
  --application-name gc-api \
  --environment-name gc-api-prod \
  --option-settings Namespace=aws:elasticbeanstalk:application:environment,OptionName=AWS_XRAY_SDK_ENABLED,Value=true
```

### 5. Start X-Ray Daemon on Beanstalk Instances

Update Elastic Beanstalk configuration in `.ebextensions/xray-daemon.config`:

```yaml
option_settings:
  aws:elasticbeanstalk:xray:
    XRayEnabled: true
```

Or include in user data to install the daemon:

```bash
# Install X-Ray daemon
sudo yum install -y aws-xray-daemon
sudo systemctl enable xray
sudo systemctl start xray
```

### 6. Instrument JDBC/SQL Queries

If you want to trace database queries, wrap your DataSource:

```java
import com.amazonaws.xray.plugins.sql.mysql.MySQLContextBuilder;
import com.amazonaws.xray.sql.mysql.ConnectionFactory;

@Configuration
public class DataSourceConfig {
    @Bean
    public DataSource dataSource() {
        DataSource ds = // your existing DataSource creation
        return ConnectionFactory.urlFactory(ds);
    }
}
```

## Viewing Traces

1. **AWS Console**: Navigate to X-Ray → Service Map to see your ALB → Beanstalk → RDS flow
2. **CloudWatch**: Check `/aws/x-ray/{environment}/insights` for anomalies
3. **Filter traces**: Use the X-Ray Group (`gc-api-traces`) in the console

## Cost Optimization

- **Dev**: 50% sampling rate = ~50K traces/day per 100K requests
- **Prod**: 10% sampling rate = ~10K traces/day per 100K requests
- X-Ray pricing: ~$0.50 per million trace records ingested
- Adjust sampling_rate in tfvars to balance visibility vs. cost

## Troubleshooting

If traces aren't showing up:

1. Verify IAM role has `xray:PutTraceSegments` permission
2. Check that X-Ray daemon is running: `sudo systemctl status xray`
3. Look for errors in Beanstalk logs: `/var/log/eb-engine.log`
4. Ensure Spring Boot has the X-Ray SDK on the classpath (check `pom.xml`)
5. Test with: `curl -X GET http://localhost:8080/v1/greetings` and check X-Ray console after 30 seconds
