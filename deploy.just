# Initialize Terraform backend in S3
init-backend:
    terraform -chdir=deploy/backend init
    terraform -chdir=deploy/backend apply

# Provision server
provision-host:
    terraform -chdir=deploy init
    terraform -chdir=deploy apply

    (cd deploy/playbooks && ansible-playbook setup.yml)