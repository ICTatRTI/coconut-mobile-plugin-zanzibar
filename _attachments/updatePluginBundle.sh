#!/bin/bash
browserify --standalone Plugin -v -t coffeeify --extension='.coffee' Plugin.coffee -o plugin-bundle.js
