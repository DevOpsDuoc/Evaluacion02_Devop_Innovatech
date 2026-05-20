## genai generated code for deploying networks on aws student

# ------------------------------------------------------------------------------
# Key Pair Configuration
# ------------------------------------------------------------------------------
variable "key_name" {
  description = "The name of the SSH key pair provided by AWS Academy"
  type        = string
  default     = "" # Ensure this matches your actual lab key name
}
