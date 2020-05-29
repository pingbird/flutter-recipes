#!/bin/bash

set -e
bundle install
bundle exec jekyll build
mv _site ~/recipes_site
git checkout gh-pages
rm -r ./*
cp ~/recipes_site/* ./
rm -r ~/recipes_site
set +e