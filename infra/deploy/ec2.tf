# =====
# just for test
# =====

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "main-key"
  public_key = tls_private_key.main.public_key_openssh
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from your local machine"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # cidr_blocks = ["44.197.117.186/32"] # your real IP
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-sg" }
}

resource "aws_security_group" "private_ec2_sg" {
  name        = "private-ec2-sg"
  description = "Allow SSH only from the bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "private-ec2-sg" }
}

resource "aws_instance" "bastion" {
  #   ami                    = "ami-0fc5d935ebf8bc3bc" # Amazon Linux 2023 (us-east-1)
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true

  tags = { Name = "bastion-host" }
}

resource "aws_instance" "private" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_1.id
  vpc_security_group_ids      = [aws_security_group.private_ec2_sg.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = false

  tags = { Name = "private host" }
}

# outputs ====================== #
output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP for bastion host"
}

output "private_ec2_private_ip" {
  value       = aws_instance.private.private_ip
  description = "Private IP for private EC2"
}

output "private_key_pem" {
  value     = tls_private_key.main.private_key_pem
  sensitive = true
}
# output "bastion_ssh_command" {
#   value = "ssh -i ~/.ssh/main-key.pem ec2-user@${aws_instance.bastion.public_ip}"
# }

# output "private_ssh_command" {
#   value = "ssh -i ~/.ssh/main-key.pem -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${aws_instance.private.private_ip}"
# }

/*
terraform output -raw private_key_pem > main-key.pem
chmod 400 main-key.pem

ssh -i main-key.pem \
    -o "ProxyCommand ssh -i main-key.pem -W %h:%p ec2-user@52.55.205.234" \
    ec2-user@10.0.71.14

sudo yum update -y
sudo yum install postgresql15 -y
sudo yum install nc -y

*/