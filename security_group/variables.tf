variable "name" {
  type = string
  default = "default-sg"
}

variable "ingress" {
  type = list(string)
  default = []
}
variable "egress" {
  type = list(string)
  default = []
}