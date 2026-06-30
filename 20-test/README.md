# Simple Elastic Beanstalk test API

This folder contains a minimal Python API that is compatible with AWS Elastic Beanstalk.

## Files
- application.py: WSGI entrypoint for the API
- requirements.txt: Python dependencies for the app
- test_app.py: Local tests for the endpoints

## Run locally
```bash
cd 20-test
python3 application.py
```

Then open:
- http://localhost:8000/
- http://localhost:8000/health

## Run tests
```bash
cd 20-test
python3 -m unittest -v
```

## Deploy to Elastic Beanstalk

### Quick deploy script
Run the helper script from this folder:

```bash
cd 20-test
./deploy.sh
```

The script will:
- package the app into a zip file
- upload it to your S3 bucket
- create a new Beanstalk application version
- update the Beanstalk environment to use that version

You can override the defaults if needed:

```bash
APP_NAME=gc-api ENV_NAME=gc-api-dev BUCKET_NAME=elasticbeanstalk-us-west-2-339087217430 ./deploy.sh
```

### Manual deploy steps
1. Zip the contents of this folder, including application.py and requirements.txt.
2. Upload the zip to your Elastic Beanstalk application version.
3. Deploy the new version.
