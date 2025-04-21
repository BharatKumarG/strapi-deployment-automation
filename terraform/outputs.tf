output "ec2_public_ip" {
  value = aws_instance.strapi_instance.public_ip
}
