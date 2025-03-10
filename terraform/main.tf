terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Security group for the EC2 instance
resource "aws_security_group" "microservices_sg" {
  name        = "microservices-security-group"
  description = "Allow traffic for microservices application"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Traefik dashboard access
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
    description = "Traefik Dashboard"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "microservices-sg"
  }
}

# EC2 instance for microservices
resource "aws_instance" "microservices_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.microservices_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "microservices-server"
  }

  # This ensures the EC2 instance has a public IP address
  associate_public_ip_address = true

  provisioner "local-exec" {
    command = <<-EOT
      echo "[microservices]" > inventory.ini
      echo "${self.public_ip} ansible_user=${var.ssh_user} ansible_ssh_private_key_file=${var.private_key_path}" >> inventory.ini
      
      sleep 60  # Wait for instance to initialize

      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini ../ansible/deploy.yml
    EOT
  }
}

# Elastic IP for stable public address
resource "aws_eip" "microservices_eip" {
  instance = aws_instance.microservices_server.id
  associate_with_private_ip = false

  tags = {
    Name = "microservices-eip"
  }
}

# Route 53 configuration - Add this section
# Get the hosted zone for your domain
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# Create an A record for the apex domain (example.com)
resource "aws_route53_record" "apex" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.microservices_eip.public_ip]
}

# Create an A record for the www subdomain (www.example.com)
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.microservices_eip.public_ip]
}

# Optional: Create additional records for subdomains (e.g., api.example.com)
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.microservices_eip.public_ip]
}

# Output the public IP address
output "server_ip" {
  value = aws_eip.microservices_eip.public_ip
}

output "ssh_command" {
  value = "ssh -i ${var.private_key_path} ${var.ssh_user}@${aws_eip.microservices_eip.public_ip}"
}

# Add domain name outputs
output "domain_name" {
  value = var.domain_name
}

output "www_domain_name" {
  value = "www.${var.domain_name}"
}

output "api_domain_name" {
  value = "api.${var.domain_name}"
}