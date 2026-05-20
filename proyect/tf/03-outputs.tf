## genai generated code for deploying networks on aws student

################################################################################
# OUTPUTS: Instance Connectivity Details
# DESCRIPTION: This section prints the Public and Private IP addresses of the 
#              deployed instances. These IPs are required for the Ansible 
#              inventory file and for performing SSH jumps.
################################################################################

# --- Web Layer Outputs ---
output "web_instance_private_ip" {
  description = "The private IP of the Web instance"
  value       = aws_instance.ec2_web.private_ip
}

output "web_eip_public_ip" {
  description = "Stable public Elastic IP of the Web/Bastion instance"
  value       = aws_eip.web_eip.public_ip
}

# --- Application Layer Outputs ---
output "app_instance_private_ip" {
  description = "The private IP of the Application instance (Use this for SSH jump from Web)"
  value       = aws_instance.ec2_app.private_ip
}

# --- Data Layer Outputs ---
output "datos_instance_private_ip" {
  description = "The private IP of the Data instance (Use this for SSH jump from App)"
  value       = aws_instance.ec2_datos.private_ip
}
