#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Must specify database: ./deploy.sh <database>"
  exit -1
fi

echo "Browserifying, uglifying and then making plugin-bundle.js"
./node_modules/browserify/bin/cmd.js --debug --standalone Plugin -v -t coffeeify --extension='.coffee' Plugin.coffee -o plugin-bundle.js

if [[ $? -eq 0 ]]; then
  echo "Pushing to cloud"
  userpass=$(cat userpass.txt) 
  database=$1
  coffee pushToCouchDB.coffee https://$userpass@zanzibar.cococloud.co $database
fi
