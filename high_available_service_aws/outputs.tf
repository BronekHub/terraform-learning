output "web_loadbalancer_url" {
  value = aws_elb.web_service.dns_name
}
