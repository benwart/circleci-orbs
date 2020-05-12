[![CircleCI](https://circleci.com/gh/ovotech/circleci-orbs.svg?style=shield&circle-token=ae0a459eabe5a6b454eab8e241a516fd1a212e8c)](https://app.circleci.com/pipelines/github/ovotech/circleci-orbs)

# CircleCI Orbs

This repo contains public circleci orbs in the ovotech namespace.

## Contributing

Orbs follow the conventions:

* **Directory** named the **same** as the orb

* A single Dockerfile in the executor directory (unless you specify publish-docker-image:false)

* The orb yaml is in a file name `orb.yml`

* Published in the ovotech namespace

* An `orb_version.txt` file may exist in an orb directory containing the version of the orb. (A new version is only published when the version changes)


## Published Orbs

 - [ovotech/aws-get-parameters@1](aws-get-parameters) - Get parameters from AWS Parameter Store.
 - [ovotech/aws-rotate-keys@1](aws-rotate-keys) - Rotate AWS access keys and update corresponding CircleCI environment variables.
 - [ovotech/clair-scanner@1](clair-scanner) - Scan Docker images for vulnerabilities.
 - [ovotech/rac-gcp-deply@1](rac-gcp-deploy) - Deploy Scala services to a Kubernetes cluster running in Google Cloud.
 - [ovotech/terraform@1](terraform) - Plan and apply Terraform modules.
 
 Other orbs in the ovotech namespace:
 - [ovotech/shipit@1](https://github.com/ovotech/pe-orbs/tree/master/shipit) - Run shipit and record deployments to https://shipit.ovotech.org.uk.
