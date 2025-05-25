variable "home" {
  default = "/home/ubuntu"
}

variable "instance_count" {
  default = 1
}
variable "VPC_ID" {
    default = "vpc-0efdf97bd6df112ba"
  
}

variable "ssh_key_file_location" {
  default = "$~/.ssh/id_rsa"
}


variable "force_run" {
    default = "1"
  
}

variable "ansible_config_location" {
  default = "../All_Instance_Ansible"
}