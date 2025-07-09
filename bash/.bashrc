# Source shared shell configurations
for file in ~/.shell/{exports,aliases,functions,completions}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file"
done