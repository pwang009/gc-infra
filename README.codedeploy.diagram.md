                         ┌──────────────────────────┐
                         │        Developer         │
                         │        pushes code       │
                         └─────────────┬────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │      GitHub Repo         │
                         └─────────────┬────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │ GitHub Actions (Build)   │
                         │  - mvn/gradle build      │
                         │  - create JAR            │
                         │  - publish 2 CodeArtifact│
                         │  - upload to S3 (EB App) │
                         │  - deploy to Dev EB      │
                         └─────────────┬────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │     AWS CodeArtifact     │
                         │  (Versioned JAR storage) │
                         └─────────────┬────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │   Dev Deployment Pipeline│
                         │   (auto-triggered)       │
                         └─────────────┬────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │ Elastic Beanstalk (Dev)  │
                         │  - Private Subnets       │
                         │  - EC2 instances         │
                         │  - Pulls JAR from S3     │
                         └─────────────┬────────────┘
                                       │
                                       ▼
         ┌──────────────────────────────────────────────────────────────┐
         │                     Production Promotion Flow                │
         └──────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │ GitHub Actions (Prod)    │
                         │  - Select JAR version    │
                         │    from CodeArtifact     │
                         │  - Upload to S3 (EB App) │
                         │  - Deploy to Prod EB     │
                         └─────────────┬────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │ Elastic Beanstalk (Prod) │
                         │  - Private Subnets       │
                         │  - EC2 instances         │
                         │  - Pulls JAR from S3     │
                         └─────────────┬────────────┘
                                       │
                                       ▼
                         ┌──────────────────────────┐
                         │   ALB (Public Subnets)   │
                         │   Routes traffic to Prod │
                         └──────────────────────────┘
