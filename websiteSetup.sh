#!/usr/bin/env bash

# Notes
# tenant is in the form abc123.live.dynatrace.com for SaaS
# or {your-domain}/e/{your-environment-id} for Managed
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
paas_token=***

###########################################
# DO NOT MODIFY ANYTHING BELOW THIS LINE. #
###########################################

sudo apt update -y
sudo apt install jq -y
wget https://raw.githubusercontent.com/keptn-contrib/dynatrace-service/release-0.6.1/deploy/scripts/applyAutoTaggingRules.sh
wget https://raw.githubusercontent.com/keptn-contrib/dynatrace-service/release-0.6.1/deploy/scripts/utils.sh
chmod +x applyAutoTaggingRules.sh && chmod +x utils.sh
./applyAutoTaggingRules.sh $tenant $api_token
wget -O Dynatrace-OneAgent-Linux.sh "https://$tenant/api/v1/deployment/installer/agent/unix/default/latest?arch=x86&flavor=default" --header="Authorization: Api-Token $paas_token"
sudo /bin/sh Dynatrace-OneAgent-Linux.sh --set-app-log-content-access=true --set-infra-only=false --set-host-group=website
sudo apt install php -y
sudo wget https://raw.githubusercontent.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/master/indexV1.php -O /var/www/html/index.php
sudo rm /var/www/html/index.html
echo export DT_CUSTOM_PROP=\"keptn_stage=quality keptn_project=website keptn_service=front-end keptn_deployment\" | sudo tee --append /etc/apache2/envvars > /dev/null
sudo service apache2 restart
wget https://github.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/raw/master/loadGen.sh
chmod +x loadGen.sh
nohup ./loadGen.sh &

