# Initialize Terraform backend in S3
init-backend:
    terraform -chdir=deploy/backend init
    terraform -chdir=deploy/backend apply -auto-approve

# Destroy Terraform backend in S3
destroy-backend:
    terraform -chdir=deploy/backend destroy

# Create + provision server
provision-host:
    terraform -chdir=deploy init
    terraform -chdir=deploy apply -auto-approve

    (cd deploy/playbooks && ansible-playbook setup.yml)

# Destroy server
destroy-host:
    terraform -chdir=deploy destroy

# Access server
connect-server:
    ssh -o StrictHostKeyChecking=no -i deploy/harjus-ec2-key.pem admin@$(terraform -chdir=deploy output instance_ip|sed 's/"//g')