#!/usr/bin/env bash

####################################
# WARNING: DO NOT MODIFY THIS FILE #
####################################

tenant=$(cat websiteSetup.sh | grep "tenant=" | cut -s -d "=" -f2)
api_token=$(cat websiteSetup.sh | grep "api_token=" | cut -s -d "=" -f2)
currentTimeMillis=$(date +%s%N | cut -b1-13)

# Push V2 Webpage
sudo wget https://raw.githubusercontent.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/master/indexV3.php -O /var/www/html/index.php

# Push DT Event
curl -X POST "https://$tenant/api/v1/events" -H "accept: application/json" -H "Authorization: Api-Token $api_token" -H "Content-Type: application/json" -d "{ \"eventType\": \"CUSTOM_DEPLOYMENT\", \"start\": $currentTimeMillis, \"end\": $currentTimeMillis, \"attachRules\": { \"tagRule\": [{ \"meTypes\": [\"SERVICE\"], \"tags\": [{ \"context\": \"CONTEXTLESS\", \"key\": \"keptn_deployment\" }, { \"context\": \"CONTEXTLESS\", \"key\": \"keptn_project\", \"value\": \"website\" }, { \"context\": \"CONTEXTLESS\", \"key\": \"keptn_service\", \"value\": \"front-end\" }, { \"context\": \"CONTEXTLESS\", \"key\": \"keptn_stage\", \"value\": \"quality\" } ] }] }, \"source\": \"Pipeline Tool\", \"deploymentName\": \"Release v3\", \"deploymentVersion\": \"v3\"}"
