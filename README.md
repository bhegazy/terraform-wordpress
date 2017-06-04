
# Terraform-wordpress

This is an example of fully automated deployment of wordpress app to aws using Terraform, ansible and shell script.

## Prerequisite

1. Install [Terraform](https://www.terraform.io/intro/getting-started/install.html)
2. Install [Ansible](http://docs.ansible.com/ansible/intro_installation.html)
3. Install [awscli](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
4. [Configure awscli](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) with key and secret (`aws configure`)

### Quickstart

1. git clone git@github.com:bhegazy/terraform-wordpress.git
2. cd terraform-wordpress
3. `./deploy.sh --app=<app_name> --environment=<environment> --num=<number_of_aws_instances> --size=<aws_instance_size>`
 

### Example

`./deploy.sh --app=test --environment=staging --num=2 --size=t2.micro`

The script above will output AWS ELB DNS address, which is where wordpress is hosted.

### Clean-up

`rm ansible-key* && terraform destroy terraform`

### Declaimer 

DO NOT USE IN PRODUCTION THIS IS ONLY CREATED AS AN EXAMPLE.

### TODO

* Create mysql db using AWS RDS.
* Create Dockerfile for wordpress app.


