#!/bin/bash
echo "Browserifying, uglifying and then making plugin-bundle.js"
rm plugin-bundle.js bundle.js
./node_modules/browserify/bin/cmd.js --standalone Plugin -v -t coffeeify --extension='.coffee' Plugin.coffee -o bundle.js

if [[ $? -eq 0 ]]; then
  npx terser bundle.js > plugin-bundle.js
  echo "Pushing to cloud"
  userpass=$(cat userpass.txt) 
  coffee pushToCouchDB.coffee https://$userpass@zanzibar.cococloud.co zanzibar
fi
