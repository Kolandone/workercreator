#!/bin/bash

# Log into Ubuntu using proot-distro and run the script from the URL
proot-distro login ubuntu -- bash -c "bash <(curl -fsSL https://raw.githubusercontent.com/Kolandone/workercreator/main/kol.sh)"
