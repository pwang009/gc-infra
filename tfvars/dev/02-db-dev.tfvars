# Database Module - Development Configuration
region = "us-west-2"
environment = "dev"
terraform_state_bucket = "gc-terraform-state-c8f7ewhysy5w"
db_name = "goodconnex"
aurora_mode = "serverless"
instance_class = "db.serverless"
instance_count = 1
enable_proxy = false
external_rds_ips = ["70.181.86.188/32"]
   
# Redis (ElastiCache) - small single-node for dev
enable_redis = true
redis_engine = "valkey"
redis_node_type = "cache.t4g.micro"
redis_engine_version = "9.0"
redis_parameter_group_name = "default.valkey9"

