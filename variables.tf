variable "password" {
  type = string
}

variable "username" {
    type = string
}

variable "account_name" {
  type = string
}

variable "organization_name" {
    type = string
}

variable "database" {
  type = string
}

variable "schema" {
    type = string
}

variable "database_roles" {
    description = "Database roles such as DATA_ENGINEER, DATA_ANALYST..."
    type = list(string)
}

variable "users" {
  type = map(object({
    login_name = string
    password = string
    roles = list(string)
  }))
}

variable "privileges_for_users" {
    type = map(list(string))
}
