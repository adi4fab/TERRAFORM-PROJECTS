variable "region" {
  default = "eu-west-1"
  description = "the region in which you wanna deploy"
  type = string
}

variable "cidr" {
  description = "The CIDR block"
  type = string
}

variable "pub-sub-1-cidr" {
  description = "public subnet 1 cidr"
  type = string
}

variable "pub-sub-2-cidr" {
  description = "public subnet 2 cidr"
  type = string
}

variable "pub-sub-3-cidr" {
  description = "public subnet 3 cidr"
  type = string
}

variable "pri-sub-1-cidr" {
  description = "private subnet 1 cidr"
  type = string
}

variable "pri-sub-2-cidr" {
  description = "private subnet 2 cidr"
  type = string
}

variable "pri-sub-3-cidr" {
  description = "private subnet 3 cidr"
  type = string
}