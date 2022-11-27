#!/bin/sh

case "$1" in 
    "serve" | "server")
         hugo server --bind=0.0.0.0 --buildDrafts
        ;;
    *) echo "pls use 'serve' or 'server'!"
        ;;
esac
