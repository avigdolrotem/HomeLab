#!/bin/bash
# Test script to validate user-data changes

echo "Testing user-data script changes..."

# Validate syntax
if bash -n infrastructure/terraform/environments/dev/user-data.sh; then
    echo "✅ Bash syntax validation passed"
else
    echo "❌ Bash syntax validation failed"
    exit 1
fi

# Check for potential issues
echo "Checking for potential issues..."

# Check for proper error handling
if grep -q "set -euo pipefail" infrastructure/terraform/environments/dev/user-data.sh; then
    echo "✅ Proper error handling enabled"
else
    echo "⚠️  Consider adding 'set -euo pipefail' for better error handling"
fi

# Check for logging
if grep -q "log()" infrastructure/terraform/environments/dev/user-data.sh; then
    echo "✅ Logging function found"
else
    echo "⚠️  Consider adding logging for debugging"
fi

# Check for service conflict handling
if grep -q "postfix" infrastructure/terraform/environments/dev/user-data.sh; then
    echo "✅ Postfix conflict handling found"
else
    echo "⚠️  Consider handling postfix service conflicts"
fi

echo "User-data validation complete!"