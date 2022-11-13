set -euo pipefail

function get-www-distribution-id-for-this-domain() {
  all_dists=$(aws cloudfront list-distributions | jq '.DistributionList.Items[]')
  the_dist=$(echo "$all_dists" | jq --arg domain_name "$1" 'select(.Aliases.Items[] | contains($domain_name) and contains("www"))')
  dist_id=$(echo "$the_dist" | jq -r .Id)
  echo "$dist_id"
}


# start of procedural code
read -p "Enter your domain name : " domain_name

echo "Looking for a hosted zone in route53 for this domain..."

this_domains_hosted_zone=$(aws route53 list-hosted-zones | jq --arg domain_name "$domain_name" '
  .HostedZones[]
  | select(.Name | contains($domain_name))')

id_of_hosted_zone=$(echo "$this_domains_hosted_zone" | jq -r .Id)

# if hosted zone is not found for the given domain
if [[ -z "$id_of_hosted_zone" ]]; then
  echo "Failed to find any hosted zones in route53 with the domain name: ${domain_name}"
  exit 1
fi


echo "Found the hosted zone for the given domain... ID: ${id_of_hosted_zone}"

echo "Creating an S3 bucket to store the terraform state"

terraform_state_bucket="${domain_name}-terraform-state"

# Create an s3 bucket to store the terraform state
aws s3api create-bucket --bucket "$terraform_state_bucket"

cd infra/

# write the domain name to the terraform variables
echo "domain_name = \""$domain_name"\"

common_tags = {
  Project = \""$domain_name"\"
}" > terraform.tfvars

# variables for the S3 state storage
echo "bucket = \"${terraform_state_bucket}\"
key = \"terraform.tfstate\"
region = \"us-east-1\"
" > backend.conf

terraform init --backend-config=backend.conf

# import the existing hosted zone created by AWS for your domain so that it can be managed by terraform
terraform import aws_route53_zone.main "$id_of_hosted_zone"

terraform apply -auto-approve

distribution_id=$(get-www-distribution-id-for-this-domain "$domain_name")

# write the commands to update the html file for the static site
echo "aws s3 sync ./src s3://www.${domain_name}
aws cloudfront create-invalidation --distribution-id ${distribution_id} --paths "/*";" > ../update.sh

echo "Uploading a template index.html file\n"
echo "Modify the files in src/ and use update.sh to update the content of the site"

aws s3 sync ../src s3://www.${domain_name}
aws cloudfront create-invalidation --distribution-id ${distribution_id} --paths "/*";
