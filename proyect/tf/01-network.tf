## genai generated code for deploying networks on aws student

################################################################################
# PROJECT: AWS Academy Network Infrastructure
# DESCRIPTION: This Terraform script deploys a standard 3-tier VPC architecture
#              (Web, Application, and Data layers) across two Availability Zones.
################################################################################

# ------------------------------------------------------------------------------
# 1 & 2. Virtual Private Cloud (VPC)
# ------------------------------------------------------------------------------
# Creates the main network boundary. 
# CIDR 10.0.0.0/20 provides 4,096 IP addresses.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/20"
  enable_dns_support   = true # Required for AWS internal DNS resolution
  enable_dns_hostnames = true # Assigns public DNS names to instances with public IPs
  tags = {
    Name = "academy-vpc"
  }
}

# Availability Zones (AZs)
# Using a list of AZs to ensure high availability by distributing resources.
locals {
  azs = ["us-east-1a", "us-east-1b"]
}

# ------------------------------------------------------------------------------
# 3. Subnet Architecture (3-Tier Layering)
# ------------------------------------------------------------------------------

# 3.1 Public Subnets (Web Layer)
# These subnets are accessible from the internet. Used for Load Balancers or Bastion hosts.
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # cidrsubnet splits the VPC /20 into /24 chunks. 
  # Indices: 0 -> 10.0.0.0/24, 1 -> 10.0.1.0/24
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index) 
  availability_zone = local.azs[count.index]
  map_public_ip_on_launch = true # Automatically assign public IPs to instances here
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# 3.2 Private Subnets (App Layer)
# Logic: Isolated from direct internet access. Holds the application logic/servers.
resource "aws_subnet" "private_app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # Offsets the index by 2 to avoid overlapping with public subnets.
  # Indices: 2 -> 10.0.2.0/24, 3 -> 10.0.3.0/24
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 2) 
  availability_zone = local.azs[count.index]
  tags = {
    Name = "private-app-subnet-${count.index + 1}"
  }
}

# 3.3 Private Subnets (Data Layer)
# Logic: Maximum isolation. Holds databases (RDS) and caching layers.
resource "aws_subnet" "private_data" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  # Offsets the index by 4.
  # Indices: 4 -> 10.0.4.0/24, 5 -> 10.0.5.0/24
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 4) 
  availability_zone = local.azs[count.index]
  tags = {
    Name = "private-data-subnet-${count.index + 1}"
  }
}

# ------------------------------------------------------------------------------
# 4. Connectivity & Gateways
# ------------------------------------------------------------------------------

# 4.1 Internet Gateway (IGW)
# Allows communication between the VPC and the internet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "academy-igw"
  }
}

# 4.2 NAT Gateway
# Allows instances in private subnets to reach the internet (for updates) 
# but prevents the internet from initiating a connection to them.

# Elastic IP required for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# The NAT Gateway itself (deployed in the first public subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id 
  tags = {
    Name = "academy-nat"
  }
  # Critical: The IGW must exist before the NAT Gateway is created
  depends_on = [aws_internet_gateway.igw]
}

# ------------------------------------------------------------------------------
# Routing Tables (Traffic Control)
# ------------------------------------------------------------------------------

# Public Route Table: Routes all 0.0.0.0/0 traffic to the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

# Private Route Table: Routes all 0.0.0.0/0 traffic to the NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private-rt"
  }
}

# --- Route Table Associations ---
# Links the subnets to their respective routing rules

# Associate Public Subnets -> Public RT
resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Associate App Subnets -> Private RT
resource "aws_route_table_association" "app_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Associate Data Subnets -> Private RT
resource "aws_route_table_association" "data_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# ------------------------------------------------------------------------------
# 4.3 VPC Endpoint for S3
# ------------------------------------------------------------------------------
# A Gateway Endpoint allows the VPC to communicate with S3 without using 
# the NAT Gateway, reducing costs and improving security.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.us-east-1.s3" 
  
  # The endpoint updates the route tables automatically to direct S3 traffic internally
  route_table_ids = [
    aws_route_table.public_rt.id,
    aws_route_table.private_rt.id
  ]
  tags = {
    Name = "s3-gateway-endpoint"
  }
}
