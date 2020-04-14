#!/bin/sh
hexo g 
git add .
git commit -m "$1"
git push