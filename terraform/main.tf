# =================================================================
# VPC AND NETWORKING CONFIG
# =========================================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.config["project"]}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.config["project"]}-igw"
  }
}

# Availability Zones

data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnets

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.config["project"]}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.config["project"]}-public-b"
  }
}

# Private Subnets

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.config["project"]}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${local.config["project"]}-private-b"
  }
}

# Public Route Table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.config["project"]}-public-rt"
  }
}

# Associate Public Subnets

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "${local.config["project"]}-nat-eip"
  }
}

# Single NAT Gateway in Public Subnet A

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "${local.config["project"]}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# One Private Route Table (shared by both private subnets)

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${local.config["project"]}-private-rt"
  }
}

# Associate both private subnets with the single private route table

resource "aws_route_table_association" "private_assoc_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_assoc_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# =================================================================
# # ALB Security Group
# =========================================================================

resource "aws_security_group" "alb_sg" {
  name        = "${local.config["project"]}-alb-sg"
  description = "Allow HTTP access to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optional: enable HTTPS later on (commented example)
  # ingress {
  #   description = "HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.config["project"]}-alb-sg"
  }
}

# EC2 (App) Security Group - allows HTTP from ALB and optionally SSH from your IP
resource "aws_security_group" "ec2_sg" {
  name        = "${local.config["project"]}-ec2-sg"
  description = "Allow traffic from ALB and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # OPTIONAL - restrict this in production to your IP (replace with real CIDR)
  ingress {
    description = "SSH from admin IP (replace before use!)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # <-- change to "x.x.x.x/32"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.config["project"]}-ec2-sg"
  }
}

# RDS Security Group - only allow Postgres from EC2 SG
resource "aws_security_group" "rds_sg" {
  name        = "${local.config["project"]}-rds-sg"
  description = "Allow Postgres access from EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.config["project"]}-rds-sg"
  }
}


# =================================================================
# ALB, target group, listener, launch template, ASG
# =========================================================================

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "${local.config["project"]}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "${local.config["project"]}-alb"
  }
}

# Target Group - ALB will forward to port 80 (nginx on EC2)

resource "aws_lb_target_group" "app_tg" {
  name     = "${local.config["project"]}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "${local.config["project"]}-tg"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# IAM Role/Profile for EC2 (for SSM if you want remote manager later)

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${local.config["project"]}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags = {
    Name = "${local.config["project"]}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.config["project"]}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Launch Template - minimal bootstrap so you can SSH and deploy manually

resource "aws_launch_template" "app" {
  name_prefix   = "${local.config["project"]}-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = local.config["key_name"]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Basic bootstrap - update packages (you will still SSH and deploy manually)
              yum update -y
              
              # create deploy user for manual SSH if desired
              useradd -m deploy || true
              mkdir -p /home/deploy/.ssh
              chmod 700 /home/deploy/.ssh
              chown -R deploy:deploy /home/deploy/.ssh
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.config["project"]}-ec2"
    }
  }
}


# Auto Scaling Group

resource "aws_autoscaling_group" "app" {
  name                      = "${local.config["project"]}-asg"
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = aws_launch_template.app_lt.latest_version
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "${local.config["project"]}-ec2"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


# =================================================================
#  DB subnet group + RDS Postgres
# =========================================================================

# DB Subnet Group - RDS will use both private subnets
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${local.config["project"]}-rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "${local.config["project"]}-rds-subnet-group"
  }
}

# RDS PostgreSQL (Multi-AZ)

resource "aws_db_instance" "postgres" {
  identifier             = "${local.config["project"]}-rds"
  engine                 = "postgres"
  engine_version         = "15.3" # adjust if you want different
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100

  name                   = "backenddb"
  username               = "appuser"
  password               = local.config["db_password"]

  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = true

  backup_retention_period = 7
  deletion_protection     = false

  tags = {
    Name = "${local.config["project"]}-rds"
  }
}
