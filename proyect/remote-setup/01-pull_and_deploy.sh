#!/bin/bash
# Script de automatización de despliegue continuo para Innovatech Chile

echo "==============================================="
echo "Iniciando proceso de despliegue en AWS EC2"
echo "==============================================="

# 1. Autenticar Docker con Amazon ECR usando las credenciales del rol de la instancia
echo "Autenticando con Amazon ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# 2. Asegurar el directorio de la aplicación
cd /home/ec2-user/app || exit 1

# 3. Descargar las imágenes más recientes desde el registro privado
echo "Descargando últimas imágenes optimizadas..."
docker compose pull

# 4. Reiniciar el stack completo de contenedores en segundo plano (Ventas, Despachos, Frontend y Base de datos)
echo "Levantando servicios de la Tienda de Perritos..."
docker compose up -d --remove-orphans

echo "==============================================="
echo "Despliegue completado con éxito"
echo "==============================================="
