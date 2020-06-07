# Ear trainer

## Development

`cd uitls && python3 make_sound.py && cp -r mp3 ../deployment/mp3 && cp ..`

`elm-live src/* -- --output deployment/eartrainer.js` and open `http://localhost:8000/deployment/index.html`

## Deployment
```
elm make src/* --output deployment/eartrainer.js --optimize
DOMAIN_NAME=ear-trainer.domefasoltedo.com
IDEMPOTENCY_TOKEN=`date '+%Y%m%d'`
# Amazon CloudFront accepts ACM certificate only from us-east-1. cf. https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cnames-and-https-requirements.html#https-requirements-aws-region
CERTIFICATE_ARN=`aws acm request-certificate --domain-name ${DOMAIN_NAME} --validation-method DNS --idempotency-token ${IDEMPOTENCY_TOKEN} --region us-east-1 | jq -r '."CertificateArn"'`

# Complete valication now
# Visit https://console.aws.amazon.com/acm/home?region=us-east-1#/ and Configure DNS server.

LOGGING_BUCKET_NAME=ear-trainer-logging
CONTENT_BUCKET_NAME=ear-trainer-content

aws s3 mb s3://${LOGGING_BUCKET_NAME}
aws s3 mb s3://${CONTENT_BUCKET_NAME}

aws s3 rm --recursive s3://${CONTENT_BUCKET_NAME}
aws s3 cp --recursive deployment s3://${CONTENT_BUCKET_NAME}

aws cloudformation deploy \
  --template-file cloudformation_templates/main.yml \
  --stack-name ear-trainer \
  --parameter-override \
    DomainName=${DOMAIN_NAME} \
    LoggingBucketName=${LOGGING_BUCKET_NAME} \
    ContentBucketName=${CONTENT_BUCKET_NAME} \
    AcmCertificateArn=${CERTIFICATE_ARN}

# Configure DNS server now
# For Route 53, make two record sets: {A, AAAA} type, Alias, Alias Target=<yours>.cloudfront.net.
```

## TODO
- [ ] Add other instruments
- [x] Add a retry button
- [ ] Add a graph of scores
- [ ] Add statistics of mistake
