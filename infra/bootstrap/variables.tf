variable "project_name" {
  description = "Name of the project (used for resource tagging)"
  type        = string
  default     = "springsnap"
}

variable "owner_email" {
  description = "Email of the owner of the resources"
  type        = string
}

variable "state_bucket_names" {
  description = "Names for the S3 bucket that will hold Terraform state and lock files for dev and prod"
  type        = set(string)
  default     = toset(["springsnap-state-dev", "springsnap-state-prod"])
}
