module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.stack_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.deployment_region}a", "${var.deployment_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
}