output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.demo_api.dns_name
}
