# Deleting ws-elasticbeanstalk-ec2-role role

## commands executed
1. Listed attached policies - Found 3 policies attached
2. Detached all policies - AWSElasticBeanstalkMulticontainerDocker AWSElasticBeanstalkWebTier, AWSElasticBeanstalkWorkerTier
3. Removed role from instance profile - Disassociated the role
4. Deleted the instance profile - Cleaned up the profile
5. Deleted the IAM role - Final cleanup

## bash commands
```bash
aws iam list-attached-role-policies --role-name aws-elasticbeanstalk-ec2-role --query 'AttachedPolicies[].PolicyArn' --output text
aws iam detach-role-policy --role-name aws-elasticbeanstalk-ec2-role --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker
aws iam detach-role-policy --role-name aws-elasticbeanstalk-ec2-role --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker
aws iam detach-role-policy --role-name aws-elasticbeanstalk-ec2-role --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier
aws iam remove-role-from-instance-profile --instance-profile-name aws-elasticbeanstalk-ec2-role --role-name aws-elasticbeanstalk-ec2-role
aws iam delete-instance-profile --instance-profile-name aws-elasticbeanstalk-ec2-role
aws iam delete-role --role-name aws-elasticbeanstalk-ec2-role
```