output "strapi_alb_url" {
  description = "Strapi App Public URL"
  value       = aws_lb.strapi_alb.dns_name
}
