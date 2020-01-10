#!/bin/sh


case $1 in

  -d)  elm make --debug Main.elm --output=Demo.js
       ;;

  *) elm make --optimize Main.elm --output=Demo.js
       ;;

esac
