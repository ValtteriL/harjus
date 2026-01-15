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

# Create + provision server
# availability_zone: The AWS availability zone to deploy the instance in (e.g., ap-northeast-1a)
# Run `just deploy::measure-latency` first to find the optimal AZ
setup-server availability_zone:
    terraform -chdir=deploy/backend init
    terraform -chdir=deploy/backend apply -auto-approve

    terraform -chdir=deploy init
    terraform -chdir=deploy apply -auto-approve -var="availability_zone={{availability_zone}}"

    (cd deploy/playbooks && ansible-playbook setup.yml)

# Access server
connect-server:
    ssh -o StrictHostKeyChecking=no -i deploy/harjus-ec2-key.pem admin@$(terraform -chdir=deploy output instance_ip|sed 's/"//g')

# Deploy harjus release with QA variables
deploy:
    (cd deploy/playbooks && ansible-playbook deploy.yml -e "env=qa")

# Deploy harjus release with prod variables
deploy-prod:
    (cd deploy/playbooks && ansible-playbook deploy.yml -e "env=prod")

# Cleanup all resources
cleanup:
    terraform -chdir=deploy/backend destroy
    terraform -chdir=deploy destroy
