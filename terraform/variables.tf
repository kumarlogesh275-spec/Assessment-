variable "region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "flask-cluster"
}

variable "key_name" {
  default     = "wordpress"
  description = "EC2 key pair name for SSH into Jenkins"
}

variable "my_ip" {
  default = "0.0.0.0/0"
  #description = "Your IP in CIDR for SSH, e.g. 1.2.3.4/32"
}

