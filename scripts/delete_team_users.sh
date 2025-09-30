#!/bin/bash
# AIER Alert System - Delete Team Member IAM Users
# Cleanup script to remove all team IAM users

set -e

echo "=================================================="
echo "AIER Alert System - Delete Team IAM Users"
echo "=================================================="
echo ""

# Team members
TEAM_MEMBERS=(
    "javi"
    "shay"
    "cuoung"
    "cyberdog"
    "crystal"
)

echo "⚠️  WARNING: This will DELETE all team IAM users!"
echo ""
echo "Users to be deleted:"
for username in "${TEAM_MEMBERS[@]}"; do
    echo "  - aier-${username}"
done
echo ""

read -p "Are you sure? Type 'delete' to confirm: " CONFIRM

if [ "$CONFIRM" != "delete" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Deleting team users..."
echo ""

for username in "${TEAM_MEMBERS[@]}"; do
    USER_NAME="aier-${username}"
    
    echo "-----------------------------------"
    echo "Deleting: ${USER_NAME}"
    echo "-----------------------------------"
    
    # Check if user exists
    if ! aws iam get-user --user-name ${USER_NAME} > /dev/null 2>&1; then
        echo "  User does not exist, skipping"
        echo ""
        continue
    fi
    
    # Delete access keys
    echo "  Deleting access keys..."
    ACCESS_KEYS=$(aws iam list-access-keys --user-name ${USER_NAME} --query 'AccessKeyMetadata[].AccessKeyId' --output text)
    for key in $ACCESS_KEYS; do
        aws iam delete-access-key --user-name ${USER_NAME} --access-key-id $key
        echo "    ✓ Deleted key: $key"
    done
    
    # Detach policies
    echo "  Detaching policies..."
    ATTACHED_POLICIES=$(aws iam list-attached-user-policies --user-name ${USER_NAME} --query 'AttachedPolicies[].PolicyArn' --output text)
    for policy in $ATTACHED_POLICIES; do
        aws iam detach-user-policy --user-name ${USER_NAME} --policy-arn $policy
        echo "    ✓ Detached: $(basename $policy)"
    done
    
    # Delete login profile
    echo "  Deleting login profile..."
    aws iam delete-login-profile --user-name ${USER_NAME} 2>/dev/null && echo "    ✓ Deleted login profile" || echo "    (no login profile)"
    
    # Delete user
    echo "  Deleting user..."
    aws iam delete-user --user-name ${USER_NAME}
    echo "  ✓ Deleted ${USER_NAME}"
    echo ""
done

echo "=================================================="
echo "Team User Deletion Complete"
echo "=================================================="
echo ""
echo "All team members have been removed from AWS IAM."
echo ""
echo "Credentials files remain in: team-credentials/"
echo "Delete them manually: rm -rf team-credentials/"
echo ""
