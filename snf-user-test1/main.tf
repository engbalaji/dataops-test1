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
  username = "ENGBALAJI"
  password = "Creative#%19771024"
  role     = "ACCOUNTADMIN"
}

resource "snowflake_role" "example_role" {
  name    = "example_role"
  comment = "This is an example role created via Terraform"
}

resource "snowflake_user" "example_user" {
  name          = "DATAOPSU2"
  password      = "StrongPassword123!" # Consider using a secure method to store passwords
  comment       = "Example user created via Terraform"
  email         = "example_user@example.com" # Optional
  default_role  = snowflake_role.example_role.name
}

# Grant the role to the user
resource "snowflake_role_grants" "example_role_grants" {
  role_name = snowflake_role.example_role.name
  users     = [snowflake_user.example_user.name]
}


