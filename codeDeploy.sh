# Replace with your actual bucket and file name
aws s3 cp target/my-app.jar s3://my-deploy-bucket/versions/my-app-v1.jar

aws elasticbeanstalk create-application-version \
    --application-name "gc-api" \
    --version-label "v1.0.0" \
    --source-bundle S3Bucket="my-deploy-bucket",S3Key="versions/my-app-v1.jar" \
    --description "Production deployment v1.0.0"

aws elasticbeanstalk update-environment \
    --environment-name "gc-api-prod" \
    --version-label "v1.0.0"