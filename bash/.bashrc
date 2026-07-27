#!/usr/bin/env bash

# Source shared shell configurations
for file in ~/.shell/{exports,aliases,functions,keybindings,completions}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
