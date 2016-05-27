#!/bin/bash
./node_modules/browserify/bin/cmd.js --standalone Plugin -v -t coffeeify --extension='.coffee' Plugin.coffee -o plugin-bundle.js
