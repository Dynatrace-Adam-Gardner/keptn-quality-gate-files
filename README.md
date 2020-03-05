# keptn-quality-gate-files

![system architecture](assets/architecture.png)

Files and resources to demonstrate usage of Keptn Quality Gates in non-cloud setups.

The files here help to create a demo system with a 2 VM setup.

## VM1: Website + Load Generator
This VM should be an Ubuntu `t3.small` with 20GB HDD space.

### VM1 Setup
1. Launch an `Ubuntu Server 18.04` instance in EC2. Give it 20GB HDD space. Allow HTTP and SSH traffic.
2. SSH into the instance, then run:
```
cd ~
wget https://raw.githubusercontent.com/Dynatrace-Adam-Gardner/keptn-quality-gate-files/master/websiteSetup.sh
```
3. Open this file and modify lines `13`, `14` and `15` to reflect your details.
4. Execute this file with:
```
chmod +x websiteSetup.sh
./websiteSetup.sh
```

When this file is completed, you will have:
1. A working website running on port 80.
2. This VM will be monitored by the Dynatrace OneAgent.
3. The setup script creates some automatic tag rules in your Dynatrace environment (`keptn_deployment`, `keptn_project`, `keptn_service` and `keptn_stage`).
4. The setup launches a load generator which hits the website once every few seconds.
5. In Dynatrace you'll see the apache process group with `keptn_*` tags and two services, also tagged.
6. Notice that the service has a consistent traffic level.

Navigate to the VM IP address and you'll see `v1` of the website:

![website v1](assets/website_v1.png)

## VM2: Keptn Quality Gate Component
This VM should be an Ubuntu `t3.small` with 20GB HDD space.
