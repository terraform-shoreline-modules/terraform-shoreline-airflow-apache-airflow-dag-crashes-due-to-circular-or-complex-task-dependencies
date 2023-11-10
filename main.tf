terraform {
  required_version = ">= 0.13.1"

  required_providers {
    shoreline = {
      source  = "shorelinesoftware/shoreline"
      version = ">= 1.11.0"
    }
  }
}

provider "shoreline" {
  retries = 2
  debug = true
}

module "apache_airflow_dag_crashes_due_to_circular_or_complex_task_dependencies" {
  source    = "./modules/apache_airflow_dag_crashes_due_to_circular_or_complex_task_dependencies"

  providers = {
    shoreline = shoreline
  }
}