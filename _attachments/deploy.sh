#!/bin/bash
echo "Browserifying, uglifying and then making plugin-bundle.js"
./node_modules/browserify/bin/cmd.js --standalone Plugin -v -t coffeeify --extension='.coffee' Plugin.coffee | npx terser > plugin-bundle.js

echo "Pushing to cloud"
#couchapp push --no-atomic cloud
userpass=$(cat userpass.txt) 
coffee pushToCouchDB.coffee https://$userpass@zanzibar.cococloud.co zanzibar
