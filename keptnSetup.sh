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
sudo apt-get update -y
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
sudo apt-get install docker.io -y
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/minikube
wget https://raw.githubusercontent.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/master/creds.json
wget https://storage.googleapis.com/keptn-cli/latest/keptn-linux.tar.gz
tar xzf keptn-linux.tar.gz
rm keptn-linux.tar.gz
chmod +x keptn
sudo mv keptn /usr/local/bin/keptn
sudo minikube start --vm-driver=none
sudo chmod +rwx -R /home/$USER/.kube/
sudo chmod +rwx -R /home/$USER/.minikube/
sleep 30 # Wait for minikube to start
keptn install --platform=kubernetes --use-case=quality-gates --gateway=NodePort --creds=creds.json --verbose

#####################################
#     ONBOARD PROJECT TO KEPTN      #
#####################################
# Grab shipyard quality gate file with single "quality" stage.
wget https://raw.githubusercontent.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/master/shipyard.yaml

# Create a keptn project called 'website' containing one stage 'quality' as defined in the shipyard.yaml
keptn create project website --shipyard=shipyard.yaml

# Create a keptn service called 'front-end' in the 'website' project
keptn create service front-end --project=website

# Grab SLO file
# Thresholds are:
# Response time below 1s = pass
# Response time between 1s & 3s = warning
# Response time above 3s = fail
wget https://raw.githubusercontent.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/master/slo-quality-gates.yaml

# Tell Keptn about this file
keptn add-resource --project=website --stage=quality --service=front-end --resource=slo-quality-gates.yaml --resourceUri=slo.yaml

# Install the Dynatrace SLI provider
# This is the 'logic'. This tells keptn "how" to pull Dynatrace metrics
kubectl apply -f https://raw.githubusercontent.com/keptn-contrib/dynatrace-sli-service/0.3.0/deploy/service.yaml

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
wget https://raw.githubusercontent.com/keptn/examples/master/onboarding-carts/sli-config-dynatrace.yaml

# Tell Keptn about this file
keptn add-resource --project=website --stage=quality --service=front-end --resource=sli-config-dynatrace.yaml

echo ""
echo ""
echo "========================================================================================================="
echo "Keptn Quality Gate is now set up and ready to execute evaluations."
echo ""
echo "Run an evaluation:"
echo "keptn send event start-evaluation --project=website --stage=quality --service=front-end --timeframe=2m"
echo ""
echo "Retrieve the keptn context ID then:"
echo "keptn get event evaluation-done --keptn-context=***"
echo ""
echo "Note: Retrieving an evaluation can take a few minutes."
echo "Note: Expect calls to error until the evaluation is ready."
echo "========================================================================================================="

