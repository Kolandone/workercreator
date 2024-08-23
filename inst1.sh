apt update -y

# Install Node.js
apt install nodejs -y

# Install jq
apt-get install jq -y

# Install Wrangler
npm install -g wrangler
bash <(curl -fsSL https://raw.githubusercontent.com/Kolandone1/workercreator/main/Thek.sh)
