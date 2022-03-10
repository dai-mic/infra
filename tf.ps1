$tenant_id = c98d2fc9-def0-43ca-a603-a8a1e287fa9d 
$subscription_id = c98d2fc9-def0-43ca-a603-a8a1e287fa9d 
az login --tenant $tenant_id
az account set -s $subscription_id
terraform init -upgrade -reconfigure -backend-config="tenant_id=$tenant_id" -backend-config="subscription_id=$subscription_id" -backend-config="resource_group_name=rg-mic-tf-westeurope" -backend-config="storage_account_name=stmictfwesteurope" -backend-config="container_name=tfstate"