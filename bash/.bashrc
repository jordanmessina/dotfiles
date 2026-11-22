#!/usr/bin/env bash

# Load shared modules first, then any overrides for this machine.
for file in ~/.shell/{exports,aliases,functions,keybindings,completions} ~/.shell.local; do
    if [ -f "$file" ] && [ -r "$file" ]; then
        source "$file"
    fi
done
