variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "key_pair_name" {
  type    = string
  default = "instance_ssh_key"
}