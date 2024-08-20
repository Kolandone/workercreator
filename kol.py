#!/usr/bin/env python

import requests
import json

# ANSI escape codes for colors
RED = '\033[91m'
BLUE = '\033[94m'
GREEN = '\033[92m'
RESET = '\033[0m'  # Reset color

def fetch_worker_script(script_url):
    """Fetch the worker script from a given URL."""
    response = requests.get(script_url)
    if response.status_code == 200:
        return response.text
    else:
        print(f"Failed to fetch worker script: {response.status_code} - {response.text}")
        return None

def create_kv_namespace(api_token, account_id, kv_namespace_name):
    """Create a KV namespace and return its ID."""
    url = f'https://api.cloudflare.com/client/v4/accounts/{account_id}/storage/kv/namespaces'
    
    headers = {
        'Authorization': f'Bearer {api_token}',
        'Content-Type': 'application/json'
    }
    
    data = {
        "title": kv_namespace_name
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        namespace_id = response.json()['result']['id']
        print(f'KV namespace "{kv_namespace_name}" created successfully with ID: {namespace_id}')
        return namespace_id
    else:
        print(f'Failed to create KV namespace: {response.status_code} - {response.text}')
        return None

def create_worker(api_token, account_id, worker_name, script, kv_namespace_id=None, variable_name=None):
    """Create or update a Cloudflare Worker."""
    url = f'https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/scripts/{worker_name}'
    
    headers = {
        'Authorization': f'Bearer {api_token}',
    }

    bindings = []
    if kv_namespace_id and variable_name:
        bindings = [
            {
                "name": variable_name,
                "namespace_id": kv_namespace_id,
                "type": "kv_namespace"
            }
        ]

    # Prepare the metadata with bindings and specify module type (ESM)
    metadata = {
        "main_module": "worker.js",
        "type": "esm",  # For ES module
        "bindings": bindings
    }

    # Prepare the files for the multipart upload
    files = {
        'metadata': ('metadata', json.dumps(metadata), 'application/json'),
        'worker.js': ('worker.js', script, 'application/javascript+module'),
    }

    response = requests.put(url, headers=headers, files=files)
    
    if response.status_code == 200:
        if kv_namespace_id and variable_name:
            print(f'Worker {worker_name} created/updated successfully and bound to KV namespace with variable name "{variable_name}".')
        else:
            print(f'Worker {worker_name} created/updated successfully without KV namespace binding.')
        return True
    else:
        print(f'Failed to create/update worker: {response.status_code} - {response.text}')
        return False

def get_workers_dev_subdomain(api_token, account_id):
    """Retrieve the workers.dev subdomain for the Cloudflare account."""
    url = f'https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/subdomain'
    
    headers = {
        'Authorization': f'Bearer {api_token}',
        'Content-Type': 'application/json'
    }
    
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        subdomain = response.json()['result']['subdomain']
        print(f'Workers.dev subdomain retrieved: {subdomain}')
        return subdomain
    else:
        print(f'Failed to retrieve workers.dev subdomain: {response.status_code} - {response.text}')
        return None

def generate_worker_link(worker_name, subdomain):
    """Generate the default workers.dev URL for the worker."""
    return f"https://{worker_name}.{subdomain}.workers.dev"

def publish_worker_on_workers_dev(api_token, account_id, worker_name):
    """Publish the worker on the workers.dev subdomain."""
    url = f'https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/scripts/{worker_name}/subdomain'
    
    headers = {
        'Authorization': f'Bearer {api_token}',
        'Content-Type': 'application/json'
    }
    
    data = {"enabled": True}
    
    response = requests.post(url, headers=headers, json=data)  # Changed from PUT to POST
    
    if response.status_code == 200:
        print(f'Worker "{worker_name}" published on workers.dev subdomain successfully.')
        return True
    else:
        print(f'Failed to publish worker on workers.dev subdomain: {response.status_code} - {response.text}')
        return False

def list_workers(api_token, account_id):
    """List all Cloudflare Workers."""
    url = f'https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/scripts'
    
    headers = {
        'Authorization': f'Bearer {api_token}',
        'Content-Type': 'application/json'
    }
    
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        workers = response.json()['result']
        if workers:
            print("List of workers:")
            for worker in workers:
                print(f"- {worker['id']}")
        else:
            print("No workers found.")
        return workers
    else:
        print(f'Failed to list workers: {response.status_code} - {response.text}')
        return None

def delete_worker(api_token, account_id, worker_name):
    """Delete a Cloudflare Worker."""
    url = f'https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/scripts/{worker_name}'
    
    headers = {
        'Authorization': f'Bearer {api_token}',
        'Content-Type': 'application/json'
    }
    
    response = requests.delete(url, headers=headers)
    
    if response.status_code == 200:
        print(f'Worker "{worker_name}" deleted successfully.')
        return True
    else:
        print(f'Failed to delete worker: {response.status_code} - {response.text}')
        return False

def main():
    # Collecting information from the user
    api_token = input("Enter your Cloudflare API token: ")
    account_id = input("Enter your Cloudflare account ID: ")
    
    while True:
        # Display channel names with colors
        print(RED + "YOUTUBE: KOLANDONE" + RESET)
        print(BLUE + "TELEGRAM: KOLANDJS" + RESET)

        # Ask the user what action they want to perform
        print("\nChoose an action:")
        print("1: List Workers")
        print("2: Create Worker")
        print("3: Delete Worker")
        print("Type 'exit' to quit the program.")
        action = input("Enter the number of the action you want to perform or 'exit': ").strip().lower()

        if action == '1':
            list_workers(api_token, account_id)
        elif action == '2':
            worker_name = input("Enter the desired worker name: ")
            create_kv = input("Do you want to create a KV namespace? (yes/no): ").lower()
            kv_namespace_id = None
            variable_name = None
            if create_kv == 'yes':
                kv_namespace_name = input("Enter the desired KV namespace name: ")
                variable_name = input("Enter the desired variable name for the KV namespace binding: ")
                kv_namespace_id = create_kv_namespace(api_token, account_id, kv_namespace_name)
                if not kv_namespace_id:
                    print("Failed to create KV namespace.")
                    continue
            script_url = input("Enter the URL to fetch the worker script: ")
            script = fetch_worker_script(script_url)
            if script:
                subdomain = get_workers_dev_subdomain(api_token, account_id)
                if subdomain:
                    if create_worker(api_token, account_id, worker_name, script, kv_namespace_id, variable_name):
                        if publish_worker_on_workers_dev(api_token, account_id, worker_name):
                            worker_link = generate_worker_link(worker_name, subdomain)
                            print(GREEN + f'You can visit your worker at: {worker_link}' + RESET)
                        else:
                            print("Failed to publish the worker on workers.dev subdomain.")
                    else:
                        print("Failed to create the worker.")
                else:
                    print("Failed to retrieve workers.dev subdomain.")
            else:
                print("Failed to fetch the worker script.")
        elif action == '3':
            worker_name = input("Enter the name of the worker to delete: ")
            delete_worker(api_token, account_id, worker_name)
        elif action == 'exit':
            print("Exiting the program.")
            break
        else:
            print("Invalid action selected.")

# Run the main function
if __name__ == "__main__":
    main()
  
