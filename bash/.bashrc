# Source shared shell configurations
for file in ~/.shell/{exports,aliases,functions}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done