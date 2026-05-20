## genai generated code for deploying networks on aws student

################################################################################
# PROJECT: AWS Academy Compute Layer
# DESCRIPTION: This script deploys a 3-tier EC2 architecture (Web, App, Data).
#              It implements "Security Group Chaining" to ensure that traffic
#              flows strictly from Web -> App -> Data.
# FIX: Updated sg_datos to allow SSH access from sg_web for Ansible management.
################################################################################

# ------------------------------------------------------------------------------
# IAM & Role Configuration
# ------------------------------------------------------------------------------

# AWS Academy provides a pre-created IAM role called 'LabRole'.
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# Bridge between the LabRole and the EC2 instances for SSM Session Manager.
resource "aws_iam_instance_profile" "lab_profile" {
  name_prefix = "LabRoleProfile-"  # Ensures a unique, state-tracked name
  role        = data.aws_iam_role.lab_role.name
}

# Fetch the latest Amazon Linux 2023 AMI ID.
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ------------------------------------------------------------------------------
# Security Group Architecture (Traffic Chaining)
# ------------------------------------------------------------------------------

# SG Web: The "Front Door".
resource "aws_security_group" "sg_web" {
  name        = "web-sg"
  description = "Allow HTTP and SSH from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP for connectivity testing (ping)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG App: The "Middle Layer".
# UPDATED: Now allows port 3001 and 302 for both Spring Boot Backends.
resource "aws_security_group" "sg_app" {
  name        = "app-sg"
  description = "Allow traffic from web-sg and Spring Boot ports 3001/3002"
  vpc_id      = aws_vpc.main.id

  # 1. SSH access restricted to Web Layer (Bastion)
  ingress {
    description = "SSH access restricted to Web Layer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  # 2. Backend Ventas Port
  ingress {
    description     = "Spring Boot Ventas API access from Web Layer"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  # # 3. THE FIX: Backend Despachos Port
  # # This allows the frontend (on ec2-web) to call the API on port 3001.
  ingress {
    description = "Spring Boot Despachos API access from Web Layer"
    from_port   = 3002
    to_port     = 3002
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  # 4. ICMP for connectivity testing
  ingress {
    description = "ICMP from Web Layer"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = [aws_security_group.sg_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG Datos: The "Secure Core".
resource "aws_security_group" "sg_datos" {
  name        = "datos-sg"
  description = "Allow traffic from app-sg and management from web-sg"
  vpc_id      = aws_vpc.main.id

  # RULE 1: Allow Database traffic from the Application layer
  ingress {
    description = "Database Port (MySQL) restricted to App Layer"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  }

  # RULE 2: Allow SSH from the Web layer (THE FIX)
  # This allows the Bastion (ec2-web) to run Ansible playbooks on this instance.
  ingress {
    description = "SSH access restricted to Web Layer (Bastion)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  ingress {
    description = "ICMP from App Layer"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = [aws_security_group.sg_app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# Compute Instances (EC2)
# ------------------------------------------------------------------------------

# EC2 Web Instance
resource "aws_instance" "ec2_web" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.sg_web.id]
  iam_instance_profile  = aws_iam_instance_profile.lab_profile.name
  key_name             = var.key_name

  tags = { Name = "ec2-web" }
}

resource "aws_eip" "web_eip" {
  instance   = aws_instance.ec2_web.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# EC2 App Instance
resource "aws_instance" "ec2_app" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.private_app[0].id
  vpc_security_group_ids = [aws_security_group.sg_app.id]
  iam_instance_profile  = aws_iam_instance_profile.lab_profile.name
  key_name             = var.key_name

  tags = { Name = "ec2-app" }
}

# EC2 Datos Instance
resource "aws_instance" "ec2_datos" {
  ami                  = data.aws_ami.amazon_linux_2023.id
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.private_data[0].id
  vpc_security_group_ids = [aws_security_group.sg_datos.id]
  iam_instance_profile  = aws_iam_instance_profile.lab_profile.name
  key_name             = var.key_name

  tags = { Name = "ec2-datos" }
}
