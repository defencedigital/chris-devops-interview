# DevOps interview code review

## The problem

We have built a containerised application which we need to deploy to the cloud (AWS).  We need our container to be orchestrated so that in the future we may

- add extra containerised micro services
- co locate and apply auto scaling rules

Due to the immediacy of which the application needs to be hosted, this needs to be a stable, secure and quick solution and have therefore selected ECS.

A Postgres database is also required to be created to provide the data to the application.  For the purpose of this ticket, this database needs to be provisioned with a user but data will be imported later.

Our organisation requires that any infrastructure is created via IAC and the chosen tool to use is terraform.


## Acceptance criteria

- Create dockerfile to create container for SPA application
- Provision ECS cluster and deploy application container
- Create a Postgres DB (RDS)
- Create an ECR repository to hold the application container image
- Create security groups 
   - the app to be reached only on port 80 
   - only the app containers may talk to the RDS database
