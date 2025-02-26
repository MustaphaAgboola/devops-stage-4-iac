# variables.tf
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 22.04 LTS)"
  type        = string
  default     = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS in us-east-1
}

variable "instance_type" {
  description = "Instance type for the EC2 server"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4 GiB Memory
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the EC2 instance"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
}

variable "ssh_user" {
  description = "SSH username for the EC2 instance"
  type        = string
  default     = "ubuntu"
}

variable "admin_ip_cidr" {
  description = "CIDR block for admin access to Traefik dashboard"
  type        = string
  default     = "0.0.0.0/0"  # Replace with your IP for production
}

variable "domain_name" {
  description = "Domain name for the microservices application"
  type        = string
}