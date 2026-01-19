# Default task: list all available tasks
default:
    just --list deploy --unsorted

# Measure network latency from all AZs in ap-northeast-1 to Binance FIX endpoint
measure-latency:
    terraform -chdir=deploy/latency-measure init
    terraform -chdir=deploy/latency-measure apply -auto-approve \
        -var="target_host=fix-md.binance.com" \
        -var="target_port=9000" \
        -var="num_probes=100"
    @echo ""
    @echo "=== Measurement complete. Cleaning up resources... ==="
    terraform -chdir=deploy/latency-measure destroy -auto-approve
    @echo ""
    @echo "=== Done. Select the AZ with lowest avg RTT for deployment. ==="

# Setup Terraform backend
setup-backend:
    terraform -chdir=deploy/backend init
    terraform -chdir=deploy/backend apply -auto-approve

    terraform -chdir=deploy/backend output > .terraform-backend.conf

# Setup server
setup-server availability_zone:
    terraform -chdir=deploy init -backend-config=../.terraform-backend.conf
    terraform -chdir=deploy apply -auto-approve \
        -var="availability_zone={{availability_zone}}"

    (cd deploy/playbooks && ansible-playbook setup.yml)

# Access server
connect-server:
    ssh -o StrictHostKeyChecking=no -i deploy/harjus-ec2-key.pem admin@$(terraform -chdir=deploy output instance_ip|sed 's/"//g')

# Deploy harjus release with QA variables
# package: Path to the release package (e.g., dist/harjus.tar.gz)
deploy package:
    #!/usr/bin/env bash
    set -euxo pipefail
    package_path=$(realpath {{package}})
    cd deploy/playbooks
    ansible-playbook deploy.yml -e "env=qa" -e "package_path=$package_path"

# Deploy harjus release with prod variables
# package: Path to the release package (e.g., dist/harjus.tar.gz)
deploy-prod package:
    #!/usr/bin/env bash
    set -euxo pipefail
    package_path=$(realpath {{package}})
    cd deploy/playbooks
    ansible-playbook deploy.yml -e "env=prod" -e "package_path=$package_path"

# Cleanup server
cleanup-server:
    terraform -chdir=deploy destroy

# Cleanup server + Terraform backend
cleanup:
    terraform -chdir=deploy destroy
    terraform -chdir=deploy/backend destroy
