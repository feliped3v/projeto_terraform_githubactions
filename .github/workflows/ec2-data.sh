#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
# Copia o HTML enviado pelo Terraform
echo "<!DOCTYPE html><html><head><title>Site do Felipe</title></head><body style='text-align:center;font-family:Arial'><h1>🚀 Deploy automático com GitHub Actions + Terraform</h1><p>Site hospedado em uma instância EC2 com Apache</p></body></html>" > /var/www/html/index.html