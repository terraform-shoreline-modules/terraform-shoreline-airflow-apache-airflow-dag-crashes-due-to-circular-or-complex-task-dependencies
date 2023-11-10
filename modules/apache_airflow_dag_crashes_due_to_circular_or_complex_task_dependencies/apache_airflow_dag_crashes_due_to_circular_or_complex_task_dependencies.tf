resource "shoreline_notebook" "apache_airflow_dag_crashes_due_to_circular_or_complex_task_dependencies" {
  name       = "apache_airflow_dag_crashes_due_to_circular_or_complex_task_dependencies"
  data       = file("${path.module}/data/apache_airflow_dag_crashes_due_to_circular_or_complex_task_dependencies.json")
  depends_on = [shoreline_action.invoke_kubernetes_dag_tasks]
}

resource "shoreline_file" "kubernetes_dag_tasks" {
  name             = "kubernetes_dag_tasks"
  input_file       = "${path.module}/data/kubernetes_dag_tasks.sh"
  md5              = filemd5("${path.module}/data/kubernetes_dag_tasks.sh")
  description      = "Identify the specific task(s) causing the issue and break them down into smaller tasks that can be executed independently."
  destination_path = "/tmp/kubernetes_dag_tasks.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_kubernetes_dag_tasks" {
  name        = "invoke_kubernetes_dag_tasks"
  description = "Identify the specific task(s) causing the issue and break them down into smaller tasks that can be executed independently."
  command     = "`chmod +x /tmp/kubernetes_dag_tasks.sh && /tmp/kubernetes_dag_tasks.sh`"
  params      = ["POD_NAME","TASK_NAME","DAG_NAME"]
  file_deps   = ["kubernetes_dag_tasks"]
  enabled     = true
  depends_on  = [shoreline_file.kubernetes_dag_tasks]
}

