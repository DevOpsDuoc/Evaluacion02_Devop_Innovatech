#!/bin/bash
# remote-setup/00-init.sh

echo "=== Actualizando sistema e instalando Docker ==="
sudo yum update -y
sudo yum install docker -y

echo "=== Habilitando y arrancando el servicio de Docker ==="
sudo systemctl start docker
sudo systemctl enable docker

echo "=== Añadiendo al usuario ec2-user al grupo Docker ==="
sudo usermod -aG docker ec2-user

echo "=== Creando directorio para la aplicación ==="
mkdir -p $HOME/app

echo "¡Instancia lista! Por favor, cierra sesión y vuelve a entrar para aplicar cambios de grupo."
