variable "name_prefix" {
    description = "Prefix for the ECR repository name"
    type = string
}

variable "repository_app_names" {
    description = "List of application names in Springsnap"
    type = list(string)
    default = ["backend", "frontend"]
}

variable "kms_policy" {
    description = "Policy for the KMS key"
    type = string
}

variable "tags" {
    description = "Tags for the ECR repository"
    type = map(string)
}
