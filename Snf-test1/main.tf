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
  account  = "lglosgc-ckb61622"
  username = "AUTO_USER"
  password = "Welcome#77"
  role     = "SYSADMIN"
}

# Create a Snowflake Database
resource "snowflake_database" "example_db" {
  name = "BMDB-1"
  comment = "Database created using Terraform"
}

# Create a Schema within the Database
resource "snowflake_schema" "example_schema" {
  database = snowflake_database.example_db.name
  name     = "EXAMPLE_SCHEMA"
  comment  = "Schema created within the example database"
}

# Create a Warehouse for compute resources
resource "snowflake_warehouse" "example_wh" {
  name           = "EXAMPLE_WH"
  warehouse_size = "X-SMALL"
  auto_suspend   = 60
  auto_resume    = true
  initially_suspended = true
  comment        = "Warehouse created using Terraform"
}

# Outputs to display created resources
output "database_name" {
  value = snowflake_database.example_db.name
}

output "schema_name" {
  value = snowflake_schema.example_schema.name
}

output "warehouse_name" {
  value = snowflake_warehouse.example_wh.name
}