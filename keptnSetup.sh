#!/usr/bin/env bash

# Notes
# tenant is in the form abc123.live.dynatrace.com for SaaS
# or {your-domain}/e/{your-environment-id}
#
# API Token requires the following permissions:
#  - Access problem and event feed, metrics and topology
#  - Read log content
#  - Read configuration
#  - Write configuration
#  - Capture request data
#  - Real user monitoring JavaScript tag management

tenant=abc123.live.dynatrace.com
api_token=***

###########################################
# DO NOT MODIFY ANYTHING BELOW THIS LINE. #
###########################################

cd /home/$USER
sudo apt update

# Install k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.18.3+k3s1 K3S_KUBECONFIG_MODE="644" sh -s - --no-deploy=traefik
# Get nodes. This creates the /home/$USER/.kube directory so its necessary
kubectl get nodes
cp /etc/rancher/k3s/k3s.yaml /home/$USER/.kube/config

# Install keptn CLI
curl -sL https://get.keptn.sh | sudo -E bash
echo '{ "clusterName": "default" }' | tee creds.json > /dev/null

# Install keptn & exposes on port 80
keptn install --endpoint-service-type=LoadBalancer --creds creds.json

# Authorise keptn CLI
keptn auth --endpoint=http://localhost --api-token=$(kubectl get secret keptn-api-token -n keptn -ojsonpath={.data.keptn-api-token} | base64 --decode)

#####################################
#     ONBOARD PROJECT TO KEPTN      #
#####################################
# Grab shipyard quality gate file with single "quality" stage.
cat > shipyard.yaml <<DELIM
stages:
  - name: "quality"
DELIM

# Create a keptn project called 'website' containing one stage 'quality' as defined in the shipyard.yaml
keptn create project website --shipyard=shipyard.yaml

# Create a keptn service called 'front-end' in the 'website' project
keptn create service front-end --project=website

# Install the Dynatrace SLI provider
# This is the 'logic'. This tells keptn "how" to pull Dynatrace metrics
kubectl apply -f https://raw.githubusercontent.com/keptn-contrib/dynatrace-sli-service/0.5.0/deploy/service.yaml

# Grab SLO file
# Thresholds are:
# Response time below 1s = pass
# Response time between 1s & 2.8s = warning
# Response time above 2.8s = fail
wget https://raw.githubusercontent.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/master/slo-quality-gates.yaml

# Tell Keptn about this file
keptn add-resource --project=website --stage=quality --service=front-end --resource=slo-quality-gates.yaml --resourceUri=slo.yaml

# Create Dynatrace secret to hold tenant & API key details
# keptn uses these details to pull metrics from our tenant.
kubectl -n keptn create secret generic dynatrace --from-literal="DT_API_TOKEN=$api_token" --from-literal="DT_TENANT=$tenant"

# Apply the lighthouse config map for the website
# ConfigMaps are kubernetes 'glue' which bind configuration to pods and system components at runtime.
# In this case, we're telling the cluster that we'll use the dynatrace 'sli-provider' to judge the 'website' project.
kubectl apply -f https://raw.githubusercontent.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/master/lighthouse-source.yaml

# Download the SLI configs
# See the 'response_time_p95' in the 'slo-quality-gates.yaml' file? The file below contains the actual implementation of what that "variable" means.
# The implementation is actually using the Dynatrace API v2 syntax to pull timeseries metrics.
# It's also filtering by the auto-tag rules on our services... Which now explains why they're necessary.
wget https://raw.githubusercontent.com/keptn/examples/master/onboarding-carts/sli-config-dynatrace-no-deployment-tag.yaml

# Tell Keptn about this file
keptn add-resource --project=website --stage=quality --service=front-end --resource=sli-config-dynatrace-no-deployment-tag.yaml --resourceUri=dynatrace/sli.yaml

echo ""
echo ""
echo "========================================================================================================="
echo "Keptn Quality Gate is now set up and ready to execute evaluations."
echo ""
echo "Keptn Exposed on Port 80"
echo "API URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/bridge"
echo "API Token: $(kubectl get secret keptn-api-token -n keptn -ojsonpath={.data.keptn-api-token} | base64 --decode)"
echo ""
echo "Bridge URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/bridge"
echo "Bridge Credentials:"
echo "$(keptn configure bridge --output)"
echo ""
echo ""
echo "Run an evaluation:"
echo "keptn send event start-evaluation --project=website --stage=quality --service=front-end --timeframe=2m"
echo ""
echo "Retrieve the keptn context ID then:"
echo "keptn get event evaluation-done --keptn-context=***"
echo ""
echo "Note: Retrieving an evaluation can take a few minutes."
echo "Note: Expect calls to report "No event returned" until the evaluation is ready."
echo "========================================================================================================="

