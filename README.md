# route53-static-site-boostrap

This repo makes hosting a static site on AWS (S3) quick and easy. Plus all the resources will be
managed by terraform. Just register your domain from Route53, run the script, and write your HTML &
CSS

# Insructions

1. Register your domain with [route53](https://us-east-1.console.aws.amazon.com/route53/home#DomainRegistration:)  

2. Confirm your email address  
  You'll need to confirm your email address by responding to the email that AWS will send after
  registering the domain

3. Run the script  
  `bash launch-static-site.sh`  
  It will prompt you to enter the domain name that you registered on Route53  

## Dependencies:
- terraform
- aws cli tool

## terraform state storage
By default this script will create an s3 bucket in AWS called {domain_name}-terraform-state to store
the terraform state

## Updating the HTML & CSS
After you run `launch-statis-site.sh` and the infrastructure for your static site is setup you can
modify the files in `src/` and then run `update.sh` to deploy new versions of the site


