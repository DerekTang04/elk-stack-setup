# About ELK from Ansible
This document outlines the deployment, maintenance, and usage of Reactome's ELK server on AWS.



## Deployment Process
The deployment process runs in a manually triggered Github Action, and it can be broken into 4 parts.

##### 1. Decryption
- Ansible encryption key is retrieved from Github secrets.
- Ansible vault files in `credentials/` are decrypted.

##### 2. Templating
- Github variables and secrets from the previously decrypted files are set as environment variables.
- Config files, both secret and public, are made by filling in `.template` files with the environment variables.

##### 3. Build Usagetype Artifacts
- Logstash uses a custom plugin, usagetypes, that must be built.
- All necessary files are located in `usagetype-plugin/`.
- Compilation is done in a Docker container and is triggered with the `run_docker.bash` script.
- Build artifacts are copied from the Docker container to `elk-stack/setup/ls-config/usagetype-artifacts/` (Note: this folder is auto-generated when the workflow runs).

##### 4. Ansible Deployment
- The `elk-stack/` folder, complete with config files and build artifacts, is compressed into a tarball.
- The Ansible playbook deploys the application in several steps.
 - Provision the EC2 instance (Note: A user_data script is included to do initial setup on the server, see `user_data.template`).
 - Create folders and files for handling data.
 - Transfer `elk-stack.tar.gz` tarball and extract.
 - Setup cron jobs.
 - Download essential artifacts not contained within the repo, like `ips_with_usage_types.csv`.
 - Launch the ELK stack Docker Compose using `launch_stack.bash`.



## Maintenance
Maintenance of the ELK server is handled by both automatic and manual processes.

##### Automatic Processes
Note: times listed below are with respect to the EC2 instance's clock.

- Nightly at 1:00 AM, `cycle_kib_certs.bash` runs to update Kibana's SSL certificates. Certbot automatically renews certificates for SSL, and Kibana will only use the renewed certificates when "poked".
- Nightly at 1:30 AM, `clear_logs.bash` runs to clear indexed log files. This frees storage space on the server by removing redundant logs.
- Nightly at 2:00 AM, `sync_apache_logs.bash` runs to pull log files from S3. New logs are automatically downloaded for indexing. See [Controlling Log Downloads](#controlling-log-downloads).

##### Manual Processes
- Kibana saved objects should be exported and saved to S3 after any major changes. **Otherwise, work with visualizations and dashboards may be lost!** See [Managing Saved Objects in Kibana](https://www.elastic.co/guide/en/kibana/current/managing-saved-objects.html).



## Usage
This section contains information on how to control log downloading and minimize operation costs.

##### Controlling Log Downloads
The data ingest folder is structure as such:

```
.
└── ingest/
    ├── .syncinclude
    ├── idg/
    │   └── .syncexclude
    ├── main/
    │   └── .syncexclude
    └── reactomews/
        └── .syncexclude
```

To understand how downloading works, take working with `idg` logs as an example.
1. Imagine an empty download list.
2. To the list, add `idg` logs that match the patterns in `ingest/.syncinclude`.
3. From the list, remove `idg` logs that match the patterns in `ingest/idg/.syncexclude`.
4. Download whatever is left in the list.

So, to download all logs from 2023 and 2024 for every category, add `*2023*` and `*2024*` to the `.syncinclude` file, and leave all `.syncexclude` files blank.

Note: the .syncinclude is shared across all 3 log types, while each log type has its own .syncexclude.
Note: any log pulled by the sync script will be added to the .syncexclude file associated with that type of log automatically.

##### Reducing Costs
The ELK server runs on a t3a.2xlarge instance with bursting set to unlimited mode. This allows for enhanced perforamce but can result in extra charges if used improperly. Before running a large compute load, like indexing a year, do the following:
- Check the ELKUsageMetrics dashbaord in CloudWatch for CPUCreditBalance and CPUSurplusCreditBalance (Note: update the `InstanceId` field with that of the ELK server if necessary).
- Ideally, CPUCreditBalance is at a maximum, 4608 for a t3a.2xlarge instance, and CPUSurplusCreditBalance is equal to 0.

When operating above 40% CPUUtilization, baseline for t3a.2xlarge instance, the following happens:
1. CPUCreditBalance starts to deplete.
2. Once CPUCreditBalance depletes, CPUSurplusCreditBalance starts to increase.
3. Once CPUSurplusCreditBalance reaches a maximum, 4608 for a t3a.2xlarge instance, additional charges start to apply.
See []() and []() for more details.
