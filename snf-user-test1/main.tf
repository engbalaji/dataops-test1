# Terraform Script to Create a Database in Snowflake

# Configure the Snowflake provider
terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.70.0" # Update to the latest version if needed
    }
  }
}

provider "snowflake" {
  account  = "cnclizz-lsb42651"
  username = "DATAOPSU1"
  password = "Creative#%1977"
  role     = "SYSADMIN"
}

resource "snowflake_role" "example_role" {
  name = "example_role"
  comment = "This is an example role created via Terraform"
}

resource "snowflake_user" "example_user" {
  name       = "dataopsu2"
  password   = "StrongPassword123!" # Consider using random or secure password management
  comment    = "Example user created via Terraform"
  email      = "test@balaji.com" # Optional
  default_role = snowflake_role.example_role.name

  # Optional: Grant privileges to this user
  roles = [
    snowflake_role.example_role.name
  ]
}

resource "snowflake_role_grants" "example_role_grant" {
  role_name   = snowflake_role.example_role.name
  users       = [snowflake_user.example_user.name]
}


