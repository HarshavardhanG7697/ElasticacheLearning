module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  tags = {
    Name = "Elasticache-Learning-VPC"
  }
}

resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Elasticache-Learning-EC2-SG"
  }
}


resource "aws_security_group" "allow_redis_traffic" {
  name        = "allow_redis_traffic"
  description = "Allow Redis traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_web_traffic.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Elasticache-Learning-EC-SG"
  }
}

## EC2 with valkey-cli installed ##
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "main-ec2"

  instance_type          = "t3.micro"
  ami                    = "ami-0c50b6f7dc3701ddd"
  vpc_security_group_ids = [aws_security_group.allow_web_traffic.id]
  subnet_id              = module.vpc.public_subnets[0]
  iam_instance_profile   = "ec2-admin"
  user_data              = file("redis_cli_installation.sh")

  tags = {
    Name = "Elasticache-Learning-EC2"
  }
}
resource "aws_elasticache_subnet_group" "elasticache-learning-subnet-group" {
  name       = "elasticache-learning-subnet"
  subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
}

resource "aws_elasticache_replication_group" "redis-cmd" {
  automatic_failover_enabled = true
  multi_az_enabled           = true
  replication_group_id       = "elasticache-learning-cmd"
  description                = "A cluster mode disabled redis cluster for testing"
  cluster_mode               = "disabled"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.t4g.micro"
  num_cache_clusters         = 2
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.elasticache-learning-subnet-group.id
  security_group_ids         = [aws_security_group.allow_redis_traffic.id]
}

resource "aws_elasticache_replication_group" "redis-cmd-encrypted" {
  automatic_failover_enabled = true
  multi_az_enabled           = true
  replication_group_id       = "elasticache-learning-cmd-encrypted"
  description                = "A cluster mode disabled redis cluster with encryption"
  cluster_mode               = "disabled"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.t4g.micro"
  num_cache_clusters         = 2
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.elasticache-learning-subnet-group.id
  security_group_ids         = [aws_security_group.allow_redis_traffic.id]

  # Enable Transit Encryption and IAM Auth
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  user_group_ids             = [aws_elasticache_user_group.redis_user_group.id]
}

resource "aws_elasticache_user" "redis_user" {
  user_id       = "elasticachelearning"
  user_name     = "elasticachelearning"
  access_string = "on ~* +@all"
  engine        = "redis"

  authentication_mode {
    type = "iam"
  }
}

resource "aws_elasticache_user_group" "redis_user_group" {
  engine        = "redis"
  user_group_id = "elasticachelearning"
  user_ids      = [aws_elasticache_user.redis_user.user_id, "default"]
}


resource "aws_elasticache_replication_group" "redis-cme" {
  automatic_failover_enabled = true
  multi_az_enabled           = true
  replication_group_id       = "elasticache-learning-cme"
  description                = "A cluster mode disabled redis cluster for testing"
  cluster_mode               = "enabled"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = "cache.t4g.micro"
  num_node_groups            = 2
  replicas_per_node_group    = 1
  parameter_group_name       = "default.redis7.cluster.on"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.elasticache-learning-subnet-group.id
  security_group_ids         = [aws_security_group.allow_redis_traffic.id]
}

resource "aws_elasticache_serverless_cache" "redis-serverless" {
  engine = "redis"
  name   = "elasticache-learning-serverless"
  cache_usage_limits {
    data_storage {
      maximum = 1
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 1000
    }
  }
  description              = "Serverless cache for testing purpose"
  major_engine_version     = "7"
  snapshot_retention_limit = 1
  subnet_ids               = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_group_ids       = [aws_security_group.allow_redis_traffic.id]
}
