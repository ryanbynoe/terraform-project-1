output "alb_dns_name" {
  value       = aws_lb.aws_biome_lb.dns_name
  description = "The domain name of the load balancer"
}