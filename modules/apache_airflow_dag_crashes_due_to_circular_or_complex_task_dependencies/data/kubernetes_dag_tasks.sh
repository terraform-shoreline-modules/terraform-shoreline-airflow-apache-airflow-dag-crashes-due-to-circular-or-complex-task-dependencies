#!/bin/bash

# Set the name of the Kubernetes pod running the Apache Airflow DAG
POD_NAME=${POD_NAME}

# Set the name of the DAG that is experiencing issues
DAG_NAME=${DAG_NAME}

# Set the name of the task that is causing circular or complex dependencies
TASK_NAME=${TASK_NAME}

# Get the status of the DAG
DAG_STATUS=$(kubectl exec $POD_NAME -c airflow-webserver -- airflow dags state $DAG_NAME)

# If the DAG is not running, start it
if [[ $DAG_STATUS != "running" ]]; then
    kubectl exec $POD_NAME -c airflow-webserver -- airflow dags unpause $DAG_NAME
fi

# Get the dependencies of the task causing issues
TASK_DEPS=$(kubectl exec $POD_NAME -c airflow-webserver -- airflow tasks list $DAG_NAME --tree | grep $TASK_NAME | awk '{print $4}')

# Create new tasks for each of the dependencies
for DEP in $TASK_DEPS; do
    kubectl exec $POD_NAME -c airflow-webserver -- airflow tasks clear $DAG_NAME $DEP
    kubectl exec $POD_NAME -c airflow-webserver -- airflow tasks create-dagrun $DAG_NAME --conf '{"parent_task_id": "$TASK_NAME"}' --wait --mark_success --local --reset_dagruns
done