output "load_balancer_dns" {
  value = aws_lb.quick_start_lb.dns_name
}