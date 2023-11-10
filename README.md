
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Apache Airflow DAG Crashes Due to Circular or Complex Task Dependencies

This incident type refers to situations where a DAG (Directed Acyclic Graph) in Apache Airflow, a popular platform for programmatically authoring, scheduling, and monitoring workflows, crashes due to circular or complex task dependencies. DAGs are used to define a workflow by specifying the order in which tasks should be executed. When there are circular dependencies between tasks, or when the dependencies are too complex, the DAG may not be able to execute properly, resulting in a crash. This can cause delays or failures in the workflow, which can impact critical business processes.

### Parameters

```shell
export NAMESPACE="PLACEHOLDER"
export AIRFLOW_POD_NAME="PLACEHOLDER"
export DAG_ID="PLACEHOLDER"
export MEMORY_LIMIT="PLACEHOLDER"
export DAG_NAME="PLACEHOLDER"
export TASK_NAME="PLACEHOLDER"
export POD_NAME="PLACEHOLDER"
```

## Debug

### Step 1: Check the status of the Airflow deployment

```shell
kubectl get deployments -n ${NAMESPACE}
```

### Step 2: Check the logs of the Airflow pod

```shell
kubectl logs ${AIRFLOW_POD_NAME} -n ${NAMESPACE}
```

### Step 3: Check the status of the DAGs

```shell
kubectl exec ${AIRFLOW_POD_NAME} -n ${NAMESPACE} airflow list_dags
```

### Step 4: Check the status of the tasks within the DAG

```shell
kubectl exec ${AIRFLOW_POD_NAME} -n ${NAMESPACE} airflow list_tasks ${DAG_ID}
```

### Step 5: Check the dependencies of the tasks within the DAG

```shell
kubectl exec ${AIRFLOW_POD_NAME} -n ${NAMESPACE} airflow list_tasks ${DAG_ID} --tree
```

## Repair


### Identify the specific task(s) causing the issue and break them down into smaller tasks that can be executed independently.

```shell
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
```