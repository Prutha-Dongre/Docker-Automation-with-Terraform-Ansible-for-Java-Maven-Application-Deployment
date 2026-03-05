provider "aws" {
  region = var.region
}

# Generate private key
resource "tls_private_key" "terraform_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.terraform_key.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  filename = "${var.key_name}.pem"
  content  = tls_private_key.terraform_key.private_key_pem
}

# Create Security Group
resource "aws_security_group" "devops_sg" {

  name        = "devops-security-group"
  description = "Allow SSH and application access"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Java App Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
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
    Name = "devops-sg"
  }
}

# Create EC2 instance
resource "aws_instance" "devops_server" {

  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.devops_sg.id
  ]

  tags = {
    Name = var.instance_name
  }

}