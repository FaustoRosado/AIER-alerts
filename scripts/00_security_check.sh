#!/bin/bash
# AIER Alert System - Security Check Before GitHub Push
# Scans for credentials, keys, and sensitive data

set -e

echo "=================================================="
echo "AIER Alert System - Security Audit"
echo "=================================================="
echo ""

cd "$(dirname "$0")/.."

echo "Scanning for sensitive data..."
echo ""

# Check for AWS credentials
echo "1. Checking for AWS credentials..."
CREDS=$(grep -r "AKIA[A-Z0-9]\{16\}" . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=venv --exclude="*.md" 2>/dev/null || true)
if [ -n "$CREDS" ]; then
    echo "   [WARNING] Found potential AWS access keys!"
    echo "$CREDS"
else
    echo "   [PASS] No AWS access keys found"
fi
echo ""

# Check for private keys
echo "2. Checking for private keys..."
KEYS=$(find . -name "*.pem" -o -name "*.key" -o -name "*_rsa" 2>/dev/null | grep -v node_modules | grep -v ".git" || true)
if [ -n "$KEYS" ]; then
    echo "   [WARNING] Found private key files!"
    echo "$KEYS"
else
    echo "   [PASS] No private key files found"
fi
echo ""

# Check for secret files
echo "3. Checking for secret files..."
SECRETS=$(find . -name "*.secret" -o -name "secrets.json" -o -name "kaggle.json" -o -name ".env" 2>/dev/null | grep -v node_modules | grep -v ".git" || true)
if [ -n "$SECRETS" ]; then
    echo "   [WARNING] Found secret files!"
    echo "$SECRETS"
else
    echo "   [PASS] No secret files found"
fi
echo ""

# Check for data files
echo "4. Checking for data files..."
DATA=$(find data -name "*.csv" -o -name "*.json" 2>/dev/null | grep -v ".gitkeep" || true)
if [ -n "$DATA" ]; then
    echo "   [INFO] Found data files (should be gitignored):"
    echo "$DATA"
else
    echo "   [PASS] No data files found"
fi
echo ""

# Check .gitignore exists
echo "5. Checking .gitignore..."
if [ -f ".gitignore" ]; then
    echo "   [PASS] .gitignore exists"
    
    # Check key patterns are in .gitignore
    PATTERNS=("*.pem" "*.key" ".env" "kaggle.json" "*.tfstate")
    MISSING=""
    for pattern in "${PATTERNS[@]}"; do
        if ! grep -q "$pattern" .gitignore; then
            MISSING="$MISSING $pattern"
        fi
    done
    
    if [ -n "$MISSING" ]; then
        echo "   [WARNING] Missing patterns in .gitignore:$MISSING"
    else
        echo "   [PASS] Key patterns found in .gitignore"
    fi
else
    echo "   [ERROR] .gitignore not found!"
fi
echo ""

# Check git status
echo "6. Checking git status..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "   Git repository initialized"
    echo ""
    echo "   Files to be committed:"
    git status --short | head -20 || true
    echo ""
    
    # Check for sensitive files in staging
    STAGED_SENSITIVE=$(git diff --cached --name-only | grep -E "\\.pem$|\\.key$|\\.env$|kaggle\\.json$|secrets\\.json$" || true)
    if [ -n "$STAGED_SENSITIVE" ]; then
        echo "   [ERROR] Sensitive files are staged!"
        echo "$STAGED_SENSITIVE"
        echo ""
        echo "   Remove with: git reset HEAD <file>"
    else
        echo "   [PASS] No sensitive files in staging area"
    fi
else
    echo "   [INFO] Git not initialized yet"
fi
echo ""

# Final summary
echo "=================================================="
echo "Security Audit Complete"
echo "=================================================="
echo ""
echo "Before pushing to GitHub:"
echo "  1. Verify no credentials above"
echo "  2. Review git status carefully"
echo "  3. Double-check .gitignore"
echo "  4. Never commit:"
echo "     - AWS credentials (*.pem, *.key)"
echo "     - API keys (kaggle.json, .env)"
echo "     - Data files (*.csv in data/)"
echo "     - Terraform state (*.tfstate)"
echo ""

# Return error if any sensitive data found
if [ -n "$CREDS" ] || [ -n "$KEYS" ] || [ -n "$SECRETS" ] || [ -n "$STAGED_SENSITIVE" ]; then
    echo "[FAIL] SECURITY ISSUES FOUND - DO NOT PUSH TO GITHUB"
    echo ""
    exit 1
else
    echo "[PASS] Security check passed - safe to push"
    echo ""
    exit 0
fi
