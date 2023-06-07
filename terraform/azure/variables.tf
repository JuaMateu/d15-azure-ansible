variable "subscription_id" {
    type = string
}

variable "client_id" {
    type = string
}

variable "client_secret" {
  type = string
}

variable "tenant_id" {
    type = string
}
variable "project" {
    type = string
  
}

variable "web_server_count" {
  type    = number
  default = 2
}