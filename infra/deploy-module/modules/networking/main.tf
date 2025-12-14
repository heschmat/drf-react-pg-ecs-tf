resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-main-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

# resource "aws_subnet" "public" {
#   count                   = length(var.public_subnet_cidrs)
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.public_subnet_cidrs[count.index]
#   map_public_ip_on_launch = true
#   availability_zone       = element(var.availability_zones, count.index)

#   tags = {
#     Name = "${var.prefix}-public-subnet-${count.index + 1}"
#   }
# }

resource "aws_subnet" "public" {
  /*
  this produces a map like:
  {
    0 = "us-east-1a"
    1 = "us-east-1b"
    ...
  }

  inside the resource block:
  - each.key is the index (0, 1, ...)
  - each.value is the AZ (e.g., "us-east-1a")
  */
  for_each = { for i, az in local.selected_azs : i => az }

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[each.key]
  availability_zone = each.value

  tags = {
    Name = "${var.prefix}-public-subnet-${each.key}"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# private subnets, NAT gateway, etc. is added here as needed ================ #

# NOTE: a NAT Gateway needs a stable public IP so the internet knows where to send return traffic.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-eip"
  }
}

/*
We need a NAT gateway for private subnets to access the internet
(e.g., for updates, downloading packages, etc.)
This example creates a single NAT gateway in the first public subnet

N.B.: In production, consider high availability with multiple NAT gateways (one per AZ)

A NAT Gateway allows private subnets (no public IPs) to:
- initiate outbound connections to the internet (updates, APIs, etc.)
- without allowing inbound connections from the internet
*/
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.prefix}-main-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.prefix}-private-rt"
  }
}

resource "aws_subnet" "private" {
  for_each = { for i, az in local.selected_azs : i => az }

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[each.key]
  availability_zone = each.value

  tags = {
    Name = "${var.prefix}-private-subnet-${each.key}"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# security groups ============================================ #


resource "aws_security_group" "public" {
  name        = "${var.prefix}-public-sg"
  description = "Security group for public resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allow_http_from
  }

  # ingress {
  #   description = "SSH"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = var.allow_ssh_from
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-public-sg"
  }
}

resource "aws_security_group" "private" {
  name        = "${var.prefix}-private-sg"
  description = "Security group for private resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From public SG"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-private-sg"
  }
}
