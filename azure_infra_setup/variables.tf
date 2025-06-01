variable "ssh_public_key" {
  default = file("~/.ssh/id_rsa.pub")
}