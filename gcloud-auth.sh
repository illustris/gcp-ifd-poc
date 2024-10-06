# Check if gcloud application-default login is active
if gcloud auth application-default print-access-token &>/dev/null; then
    echo "Already logged in with gcloud application-default."
else
    echo "No valid gcloud application-default login found. Running login..."
    gcloud auth application-default login
fi

# Check if a quota project is set
if ! gcloud auth application-default print-access-token &>/dev/null; then
    echo "Setting the quota project for gcloud application-default..."
    gcloud auth application-default set-quota-project [YOUR_PROJECT_ID]
fi

# Check if TF_VAR_billing_account is set
if [ -z "$TF_VAR_billing_account" ]; then
    read -p "TF_VAR_billing_account is not set. Please enter the billing account ID: " billing_account
    export TF_VAR_billing_account=$billing_account
    echo "TF_VAR_billing_account set to: $TF_VAR_billing_account"
else
    echo "TF_VAR_billing_account is already set to: $TF_VAR_billing_account"
fi

# Check if TF_VAR_billing_account is set
if [ -z "$TF_VAR_org_id" ]; then
    read -p "TF_VAR_org_id is not set. Please enter the billing account ID: " org_id
    export TF_VAR_org_id=$org_id
    echo "TF_VAR_org_id set to: $TF_VAR_org_id"
else
    echo "TF_VAR_org_id is already set to: $TF_VAR_org_id"
fi
