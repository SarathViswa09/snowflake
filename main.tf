terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.87"
    }
  }
}

provider "snowflake" {
  account_name =   var.account_name
  organization_name = var.organization_name
  user = var.username
  password = var.password
  role = "ACCOUNTADMIN"
}

# locals {
#   roles_privileges_pairs = flatten([
#     for roles,privs in var.roles_privileges : [
#       for priv in privs : {
#         role = roles
#         privilege = priv
#       }
#     ]
#   ])

#   role_priv_mapping = {
#     for pairs in local.roles_privileges_pairs :
#       "${pairs.role}-${replace(pairs.privileges," ","_")}" => pairs
#   }
# }

resource "snowflake_user" "user_sarath" {
  name = "sarath_tf_user_test"
  login_name = "sarath@tf.com"
  password = "sarath123!@#"
}

resource "snowflake_user" "user_sarath_dev" {
  name = "sarath_tf_user"
  login_name = "sarath@tf1.com"
  password = "sarath12!@#"
}

resource "snowflake_user" "admin_sarath" {
  name = "sarath_tf"
  login_name = "sarath@tf.co"
  password = "sarath123@#"
}

#Database information
resource "snowflake_database" "sarath_database" {
  name = var.database
}

resource "snowflake_schema" "sarath_schema" {
  database = snowflake_database.sarath_database.name
  name     = var.schema
}

resource "snowflake_table" "aws_cred" {
  database = snowflake_database.sarath_database.name
  schema = "PUBLIC"
  name = "AWS_CRED"
  column {
    name = "USER_ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "PASSWORD"
    type = "VARCHAR(20)"
  }
}

#Database roles creation
resource "snowflake_database_role" "data_db" {
  database = snowflake_database.sarath_database.name
  name = "DATA_ENGINEER"
}

resource "snowflake_database_role" "master_db" {
  database = snowflake_database.sarath_database.name
  name = "MANAGEMENT"
}

resource "snowflake_database_role" "dev_db" {
  database = snowflake_database.sarath_database.name
  name = "STAFF_ENGINEER"
}

resource "snowflake_database_role" "tester_db" {
  database = snowflake_database.sarath_database.name
  name = "TEST_ENGINEER"
}

#Database privileges
resource "snowflake_grant_privileges_to_database_role" "grant_priv_master" {
  database_role_name = "${snowflake_database.sarath_database.name}.${snowflake_database_role.dev_db.name}"
  privileges        = ["MODIFY"]
  on_database       = snowflake_database_role.dev_db.database
}

resource "snowflake_grant_privileges_to_database_role" "grant_priv_devs" {
  database_role_name = "${snowflake_database.sarath_database.name}.${snowflake_database_role.dev_db.name}"
  privileges        = ["USAGE"]
  on_database       = snowflake_database_role.dev_db.database
}

resource "snowflake_grant_privileges_to_database_role" "grant_priv_tester" {
  database_role_name = "${snowflake_database.sarath_database.name}.${snowflake_database_role.tester_db.name}"
  privileges        = ["USAGE"]
  on_database       = snowflake_database_role.tester_db.database
}

resource "snowflake_grant_privileges_to_database_role" "grant_priv_data" {
  database_role_name = "${snowflake_database.sarath_database.name}.${snowflake_database_role.data_db.name}"
  privileges        = ["MONITOR"]
  on_database       = snowflake_database_role.dev_db.database
}

