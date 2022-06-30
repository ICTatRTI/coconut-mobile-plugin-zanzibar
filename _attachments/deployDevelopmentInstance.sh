#!/bin/sh
echo "Browserifying, NOT uglifying and then making plugin-bundle.js"
./node_modules/browserify/bin/cmd.js --debug --standalone Plugin -v -t coffeeify --extension='.coffee' Plugin.coffee -o plugin-bundle.js

if [[ $? -eq 0 ]]; then
  echo "Pushing to cloud zanzibar-development"
  userpass=$(cat userpass.txt) 
  coffee pushToCouchDB.coffee https://$userpass@zanzibar.cococloud.co zanzibar-development
fi