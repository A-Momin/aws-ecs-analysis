

# ------------------------
# Security Groups
# ------------------------
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.project_name}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
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

  tags = merge(local.common_tags, { Name = "${var.project_name}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_container_instance_sg" {
  name_prefix = "${var.project_name}-ecs-"
  description = "Security group for ECS Container Instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on all ports for Dynamic Port Mapping"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Allow SSH from the same VPC"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = var.vpc_cidr_block != null ? [var.vpc_cidr_block] : []
  }

  ingress {
    description     = "Allow HTTP for Django App on Django default port from the same VPC"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    cidr_blocks = var.vpc_cidr_block != null ? [var.vpc_cidr_block] : []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecs-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
