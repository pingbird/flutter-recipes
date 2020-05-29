#!/bin/bash

set -o verbose
set -e
bundle install
bundle exec jekyll build
set +e
rm -r ~/recipes-site
rm -r ~/flutter-recipes
set -e
mv _site ~/recipes-site
git clone git@github.com:PixelToast/flutter-recipes.git ~/flutter-recipes
cd ~/flutter-recipes
rm -r ~/flutter-recipes/*
git checkout gh-pages
set +e
rm -r ~/flutter-recipes/*
set -e
cp -r ~/recipes-site/* ./
git add .
git commit -m "Auto Build" --author="Auto Build <build@tst.sh>"
git push -u origin gh-pages
rm -r ~/recipes-site
set +e