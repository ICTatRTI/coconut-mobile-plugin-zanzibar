#!/bin/sh
echo "Browserifying, NOT uglifying and then making plugin-bundle.js"
./node_modules/browserify/bin/cmd.js --standalone Plugin -v -t coffeeify --extension='.coffee' Plugin.coffee > plugin-bundle.js
echo "Pushing to cloud zanzibar-development"
#couchapp push --no-atomic --docid "_design/plugin-zanzibar-development" development

userpass=$(cat userpass.txt) 
coffee pushToCouchDB.coffee https://$userpass@zanzibar.cococloud.co zanzibar-development
