#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show menu and handle user input
function show_menu() {
    # Display channel names in colors
    echo -e "${RED}YOUTUBE: KOLANDONE${NC}"
    echo -e "${BLUE}TELEGRAM: KOLANDJS${NC}"

    echo "Choose an option or type 'exit' to quit:"
    echo "1) List all Workers"
    echo "2) Create a Worker"
    echo "3) Delete a Worker"
    read -r USER_OPTION

    case $USER_OPTION in
        1)
            list_all_workers
            ;;
        2)
            create_worker
            ;;
        3)
            delete_worker
            ;;
        "exit")
            echo "Exiting script."
            exit 0
            ;;
        *)
            echo "Invalid option selected."
            ;;
    esac
}

# Function to list all Workers and allow user to select one to get the visit link
function list_all_workers() {
    # Retrieve the list of Workers and their details
    WORKERS_DETAILS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    
    # Parse the list of Workers
    echo "List of Workers:"
    echo "$WORKERS_DETAILS" | jq -r '.result[] | .id' | nl -w1 -s') '

    # Ask the user to select a Worker to get the visit link
    echo "Enter the number of the Worker to get the visit link or type 'back' to return to the main menu:"
    read -r WORKER_SELECTION

    if [[ "$WORKER_SELECTION" =~ ^[0-9]+$ ]]; then
        # Get the Worker name based on user selection
        SELECTED_WORKER_NAME=$(echo "$WORKERS_DETAILS" | jq -r --argjson WORKER_SELECTION "$WORKER_SELECTION" '.result[$WORKER_SELECTION - 1] | .id')
        
        # Call the function to get the workers.dev subdomain for the selected Worker
        get_workers_dev_subdomain "$SELECTED_WORKER_NAME"
    elif [ "$WORKER_SELECTION" == "back" ]; then
        return
    else
        echo "Invalid selection."
    fi
}

# Function to get the workers.dev subdomain for a Worker
function get_workers_dev_subdomain() {
    local WORKER_NAME=$1
    # Retrieve the workers.dev subdomain for the given Worker name
    WORKER_SUBDOMAIN=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/subdomain" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | jq -r '.result.subdomain')

    # Check if the workers.dev subdomain was retrieved successfully
    if [ -n "$WORKER_SUBDOMAIN" ]; then
        echo -e "The visit link for ${GREEN}$WORKER_NAME${NC} is: ${GREEN}https://${WORKER_NAME}.${WORKER_SUBDOMAIN}.workers.dev${NC}"
    else
        echo "Failed to retrieve the workers.dev subdomain for $WORKER_NAME."
    fi
}

# Function to create a Worker
function create_worker() {
    # Prompt for the Worker name
    echo "Please enter a name for your Cloudflare Worker:"
    read -r WORKER_NAME

    # Prompt for the KV namespace name
    echo "Please enter a name for your KV namespace:"
    read -r KV_NAMESPACE_NAME

    # Prompt for the binding variable name
    echo "Please enter the name for the binding variable:"
    read -r BINDING_VARIABLE_NAME

    # Create the KV namespace using the Cloudflare API
    CREATE_KV_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/storage/kv/namespaces" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"title\":\"$KV_NAMESPACE_NAME\"}")

    # Extract the KV namespace ID from the response
    KV_NAMESPACE_ID=$(echo $CREATE_KV_RESPONSE | jq -r '.result.id')

    # Check if the KV namespace was created successfully
    if [ -n "$KV_NAMESPACE_ID" ]; then
        echo "KV namespace created successfully with ID: $KV_NAMESPACE_ID"

        # Create a new Cloudflare worker using wrangler and automate responses
        wrangler generate "$WORKER_NAME"

        # Change to the worker directory
        cd "$WORKER_NAME" || { echo "Failed to change directory to $WORKER_NAME"; exit 1; }

        # Update the wrangler.toml file to include the KV namespace binding
        echo "kv_namespaces = [ { binding = \"$BINDING_VARIABLE_NAME\", id = \"$KV_NAMESPACE_ID\" } ]" >> wrangler.toml

        # Prompt for the URL of the new script
        echo "Please enter the URL of the script you want to use to update index.js:"
        read -r SCRIPT_URL

        # Fetch the new script content from the URL and save it as index.js in the src directory
        curl -s "$SCRIPT_URL" -o src/index.js

        # Check if the download was successful
        if [ $? -eq 0 ]; then
            echo "New script content downloaded successfully to src/index.js."

            # Deploy the worker with the updated index.js and the KV namespace binding
            DEPLOY_RESPONSE=$(wrangler deploy)

            # Show the visit link of the deployed Worker to the user
            get_workers_dev_subdomain "$WORKER_NAME"

        else
            echo "Failed to download the new script content."
        fi
    else
        echo "Failed to create KV namespace."
        echo "Response: $CREATE_KV_RESPONSE"
    fi
}

# Function to delete a Worker
function delete_worker() {
    # Prompt for the Worker name to delete
    echo "Enter the name of the Worker you want to delete:"
    read -r DELETE_WORKER_NAME

    # Delete the selected Worker
    DELETE_RESPONSE=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts/$DELETE_WORKER_NAME" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")

    # Check if the deletion was successful
    if echo "$DELETE_RESPONSE" | grep -q '"success":true'; then
        echo "Worker $DELETE_WORKER_NAME deleted successfully."
    else
        echo "Failed to delete Worker $DELETE_WORKER_NAME."
        echo "Response: $DELETE_RESPONSE"
    fi
}

# Main script logic
echo "Please enter your Cloudflare API token:"
read -r CLOUDFLARE_API_TOKEN
export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN"
echo "Please enter your Cloudflare Account ID:"
read -r ACCOUNT_ID

# Loop to show the menu repeatedly
while true; do
    show_menu
done
