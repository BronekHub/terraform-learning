variable "aws_region" {
  description = "Enter the region where service should be deployed"
  default     = "eu-central-1"
}

variable "default_tags" {
  default = {
    Owner = "Kamil B"
  }
  type = map(string)
}

variable "default_instance_type" {
    default = "t3.micro"
}