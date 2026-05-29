#!/bin/bash
# Privacy checker - run before pushing to GitHub
# Checks for personal info that shouldn't be in public repos

echo "🔍 Checking for personal information..."

# Patterns to check (actual values, not variable names)
PATTERNS=(
    '1509341859837771859'  # Discord channel ID
    '1509436151860035664'  # Discord bot ID
    '歐嗨唷'              # Bot name
    'shunglinon'          # Discord username
    'simondou'            # Username
    'ghp_'                # GitHub token (actual token prefix)
)

# Excluded patterns (variable names, comments, documentation)
EXCLUDE_PATTERNS=(
    'DISCORD_BOT_TOKEN='  # Variable name
    '# DISCORD_BOT_TOKEN' # Comment
)

FOUND=0
for pattern in "${PATTERNS[@]}"; do
    # Exclude LICENSE file for author name
    if [ "$pattern" = "HSIANG-LIN" ]; then
        RESULT=$(grep -r "$pattern" . --include="*.md" --include="*.yaml" --include="*.py" --include="*.patch" 2>/dev/null | grep -v "LICENSE" | grep -v ".git/")
    else
        RESULT=$(grep -r "$pattern" . --include="*.md" --include="*.yaml" --include="*.py" --include="*.patch" 2>/dev/null | grep -v ".git/")
    fi
    
    # Filter out excluded patterns
    for exclude in "${EXCLUDE_PATTERNS[@]}"; do
        RESULT=$(echo "$RESULT" | grep -v "$exclude")
    done
    
    if [ -n "$RESULT" ]; then
        echo "❌ Found: $pattern"
        echo "$RESULT"
        FOUND=1
    fi
done

if [ $FOUND -eq 0 ]; then
    echo "✅ No personal information found"
    exit 0
else
    echo ""
    echo "⚠️  Remove personal info before pushing!"
    exit 1
fi
