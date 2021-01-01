variable "region" {
  default     = "eu-west-1"
  description = "This is the AWS default region"
}

variable "remote_state_bucket" {
  description = "Bucket name in AWS for layer 1 remote state"
}

variable "remote_state_key" {
  description = "Bucket key(basically just a name) for the layer2 infra"
}

variable "instance_type" {
  description = "instance type of the instance"
}

variable "key_pair" {
  description = "key par for ec2 instance"
  default     = "terraform" // just incase if you forget
}

variable "max_size" {
  description = "maximum size of the instance to be launched in autoscaling"
}

variable "min_size" {
  description = "minimum size of the instance to be running in autoscaling"
}

variable "sns_number" {
  description = "SNS topic alerts on personal phone"
  default = "+919591118167"
}