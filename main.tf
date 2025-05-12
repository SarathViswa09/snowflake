terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
  required_version = ">= 1.1.0"
}

provider "snowflake" {
  account_name      = var.account_name
  organization_name = var.organization_name
  user              = var.username
  password          = var.password
  role              = "ACCOUNTADMIN"
}

resource "snowflake_database" "db" {
  name = var.database
}

resource "snowflake_schema" "schema" {
  database = snowflake_database.db.name
  name     = var.schema
}

resource "snowflake_table" "aws_cred" {
  database = snowflake_database.db.name
  schema   = snowflake_schema.schema.name
  name     = "AWS_CRED"

  column {
    name = "USER_ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "PASSWORD"
    type = "VARCHAR(20)"
  }
}

locals {
  all_db_roles = distinct(
    concat(
      var.database_roles,
      flatten([ for u in values(var.users) : u.roles ])
    )
  )
}

resource "snowflake_database_role" "db_roles" {
  for_each = toset(local.all_db_roles)
  database = snowflake_database.db.name
  name     = each.key
}

resource "snowflake_account_role" "account_roles" {
  for_each = toset(local.all_db_roles)
  name     = each.key
}

resource "snowflake_grant_database_role" "grant_db_to_account" {
  for_each = toset(local.all_db_roles)
  database_role_name = snowflake_database_role.db_roles[each.key].fully_qualified_name
  parent_role_name   = snowflake_account_role.account_roles[each.key].name
}

resource "snowflake_user" "users" {
  for_each   = var.users
  name       = each.key
  login_name = each.value.login_name
  password   = each.value.password
}

locals {
  user_role_pairs = flatten([
    for username, uconf in var.users : [
      for r in uconf.roles : {
        user    = username
        db_role = r
      }
    ]
  ])

  user_role_map = {
    for p in local.user_role_pairs :
    "${p.user}-${p.db_role}" => p
  }
}

resource "snowflake_grant_account_role" "db_roles_to_user" {
  for_each = local.user_role_map
  role_name = snowflake_account_role.account_roles[each.value.db_role].name
  user_name = snowflake_user.users[each.value.user].name
}

locals {
  priv_pairs = flatten([
    for role, privs in var.privileges_for_users : [
      for priv in privs : {
        role      = role
        privilege = priv
      }
    ]
  ])

  priv_map = {
    for p in local.priv_pairs :
    "${p.role}-${replace(p.privilege, " ", "_")}" => p
  }
}

resource "snowflake_grant_privileges_to_database_role" "db_privs" {
  for_each = local.priv_map
  database_role_name = snowflake_database_role.db_roles[each.value.role].fully_qualified_name
  privileges = [ each.value.privilege ]
  on_database = snowflake_database.db.name
}
