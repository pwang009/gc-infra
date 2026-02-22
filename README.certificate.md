# GET A CUSTOM DOMAIN CERTIFICATE

## send the request
```bash
aws acm request-certificate --domain-name api.lishanteala.com --validation-method DNS --region us-west-1
```

## changes in godaddy.com
- add a CNAME
- name: _d7efe80df29caba041d7b0cc5868ec6e.api.lishanteala.com.
- value: _49a39449d0c1f66ff9800b12059f323a.jkddzztszm.acm-validations.aws.

in godaddy, it will display _d7efe80df29caba041d7b0cc5868ec6e.api as name

## changes added to environment.tf file
- associate certificate to alb
- port forwarding from 80 to 443
- run terraform apply