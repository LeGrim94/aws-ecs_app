# AWS ECS APP

This repo contain full Terraform code, configuration files and documentation needed to deploy and maintain a WordPress site on AWS. 

## Screenshots

Here's a screenshot of the project:

![Screenshot of the project](./docs/infrastructure.png)

## Guide

The IaC has been developed with Terraform. 

The IaC has been developed with Terraform. The architecture was designed to be deployed on different environments (dev and prod) with different configurations. The 'develop' branch differs from its production counterpart in a few aspects: it lacks validated domain solutions such as ACM certificates, public Route 53 hosted zones, etc. A mock infrastructure was set up to test core functionalities. The 'prod' environment is intended to be the ready-to-go solution from scratch.

Repo is organized as:

root
├── LICENSE
├── README.md
└── terraform
        ├── ecs    - wordpress app based on a ecs fargate cluster solution
        ├── rds    - database and bastion
        │   
        ├── frontend - alb, route53 records, acm...
        │   
        └── network    - networking and route53 configuration
    



## Architecture

- Instructions for installation



