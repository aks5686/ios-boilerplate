#!/bin/bash
# Renames this boilerplate project ("Boilerplate") to a new app name.
# Usage: ./setup.sh MyApp
set -euo pipefail

if [ $# -lt 1 ] || [ -z "$1" ]; then
  echo "Usage: $0 <NewAppName>"
  echo "Example: $0 MyApp"
  exit 1
fi

NEW_NAME="$1"
OLD_NAME="Boilerplate"
NEW_NAME_LOWER=$(printf '%s' "$NEW_NAME" | tr '[:upper:]' '[:lower:]')

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Renaming project from '$OLD_NAME' to '$NEW_NAME'..."

# 1. Bundle identifier: com.aks.Boilerplate -> com.aks.<newname, lowercase>
find . -path ./.git -prune -o -type f -name "*.pbxproj" -print | while read -r f; do
  sed -i '' "s/com\.aks\.${OLD_NAME}/com.aks.${NEW_NAME_LOWER}/g" "$f"
done

# 2. Replace all remaining textual occurrences of "Boilerplate" (project/target/scheme
#    names, class names, CI workflow, etc.) with the new app name. README.md is
#    intentionally excluded — this script only touches Xcode project files, source,
#    and CI config.
find . -path ./.git -prune -o -type f \
  \( -name "*.swift" -o -name "*.pbxproj" -o -name "*.xcworkspacedata" \
     -o -name "*.yml" -o -name "*.yaml" -o -name "*.plist" \) \
  -print | while read -r f; do
  if grep -q "$OLD_NAME" "$f" 2>/dev/null; then
    sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "$f"
  fi
done

# 3. Rename files and folders containing "Boilerplate" in their name (deepest first
#    so renaming a parent doesn't invalidate a child's path).
find . -path ./.git -prune -o -name "*${OLD_NAME}*" -print 2>/dev/null \
  | awk '{ print length, $0 }' | sort -rn | cut -d' ' -f2- | while read -r path; do
  newpath="$(dirname "$path")/$(basename "$path" | sed "s/${OLD_NAME}/${NEW_NAME}/g")"
  if [ "$path" != "$newpath" ]; then
    mv "$path" "$newpath"
  fi
done

# 4. Make sure this script stays executable.
chmod +x "$0"

echo "Done. Project renamed to '$NEW_NAME' (bundle id prefix: com.aks.${NEW_NAME_LOWER})."
