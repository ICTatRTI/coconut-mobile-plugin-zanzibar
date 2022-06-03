#!/bin/bash
echo "Browserifying, uglifying and then making plugin-bundle.js"
./node_modules/browserify/bin/cmd.js --debug --standalone Plugin -v -t coffeeify --extension='.coffee' Plugin.coffee > plugin-bundle.js

if [[ $? -eq 0 ]]; then
  echo "Pushing to cloud"
  #couchapp push --no-atomic cloud
  userpass=$(cat userpass.txt)
  coffee pushToCouchDB.coffee https://$userpass@zanzibar.cococloud.co zanzibar
fi
