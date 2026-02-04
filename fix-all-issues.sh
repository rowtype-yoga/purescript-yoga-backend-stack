#!/usr/bin/env bash
set -e

cd packages

# Fix all TypedQuery files - replace JSON.read @result with proper type annotation
echo "Fixing TypedQuery type applications..."
find . -name "TypedQuery.purs" -o -name "TypedQueryOm.purs" | while read file; do
  sed -i '' 's/JSON\.read @result/\(JSON.read row :: Either _ result\)/g' "$file"
  sed -i '' 's/JSON\.read @a/\(JSON.read row :: Either _ a\)/g' "$file"
done

echo "✅ Fixed TypedQuery files"
