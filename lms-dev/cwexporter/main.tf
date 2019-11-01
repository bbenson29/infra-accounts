data "aws_vpc" "selected" {
  id = "${var.vpc_id}"
}

variable "vpc_id" {
  default = "vpc-e38d8e86"
}

module "ec2-cwexporter" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = "cwexporter"
  instance_count         = 1

  ami                    = "ami-0b1a5c719c56d485e"
  instance_type          = "t2.nano"
  monitoring             = true
  vpc_security_group_ids = [module.cw_service_sg.this_security_group_id]
  subnet_id              = "subnet-c2380d9b"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "cw_service_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "user-service"
  description = "Security group for user-service with custom ports open within VPC, and PostgreSQL publicly open"
  vpc_id      = data.aws_vpc.selected.id
  
  ingress_cidr_blocks      = ["10.251.0.0/16"]
  ingress_rules            = ["https-443-tcp","ssh-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 9100
      to_port     = 9200
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "10.251.0.0/16"
    },
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}