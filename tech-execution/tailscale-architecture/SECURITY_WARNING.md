# Security Warning: Tailscale API Keys

## CRITICAL: Never Commit Real Keys

All Tailscale keys in this documentation are **EXAMPLES ONLY** with placeholder values.

### Example Keys in Documentation (SAFE)

These are **NOT REAL** and are safe in documentation:

```bash
# Example format - these xxx values are placeholders
tskey-api-xxxxx
tskey-auth-xxxxx-xxxxxxxxxxxxxx
tskey-auth-kHbYzX9CNTRL-AbCdEfGhIjKlMnOpQrStUvWxYz123456
```

### Real Keys (NEVER COMMIT)

Real Tailscale keys look like this and must **NEVER** be committed:

```bash
# EXAMPLE OF REAL KEY FORMAT (this specific key is fake)
tskey-auth-k5BxYt2CNTRL-7HjkP9QwErTyUiOp3SdFgHjKlMnBvCx4Z

# Real keys are:
# - 48-52 characters long
# - Start with tskey-auth- or tskey-api-
# - Contain random alphanumeric characters
# - Grant access to your Tailnet
```

## Protection Mechanisms

### 1. .gitignore Protection

The `.gitignore` file now blocks real keys:

```gitignore
# Tailscale keys - NEVER COMMIT
tskey-*
**/tskey-*
tailscale-auth-key*
**/tailscale-auth-key*
.tailscale/
**/tailscale.key
```

### 2. GitHub Advanced Security

Push protection will block commits containing:

- Patterns matching `tskey-auth-*` with real values
- Patterns matching `tskey-api-*` with real values

### 3. Best Practices

**DO:**

- Store real keys in AWS Secrets Manager
- Use environment variables for automation
- Rotate keys every 6-12 months
- Use reusable keys for infrastructure
- Set expiration dates on auth keys

**DON'T:**

- Commit keys to Git
- Share keys in Slack/email
- Store keys in plain text files
- Use same key across environments
- Leave unused keys active

## If You Accidentally Commit a Key

**IMMEDIATE ACTIONS:**

1. **Revoke the key immediately:**
   - Go to <https://login.tailscale.com/admin/settings/keys>
   - Find and delete the exposed key

2. **Notify your team:**
   - Alert project manager (Sheniese)
   - Document the incident

3. **Generate new key:**
   - Create replacement key
   - Update systems using the old key
   - Store securely in Secrets Manager

4. **Remove from Git history:**

   ```bash
   # This is complex - get help from team lead
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/file" \
     --prune-empty --tag-name-filter cat -- --all
   ```

5. **Force push (requires team approval):**

   ```bash
   # ONLY after team approval
   git push origin --force --all
   ```

## Key Storage Best Practices

### AWS Secrets Manager (Recommended)

```bash
# Store Tailscale auth key
aws secretsmanager create-secret \
  --name "prod/tailscale/auth-key" \
  --description "Tailscale auth key for production subnet routers" \
  --secret-string "tskey-auth-REAL_KEY_HERE" \
  --tags Key=Environment,Value=Production Key=Type,Value=Networking

# Retrieve in scripts
TAILSCALE_KEY=$(aws secretsmanager get-secret-value \
  --secret-id "prod/tailscale/auth-key" \
  --query SecretString \
  --output text)
```

### Environment Variables

```bash
# In your EC2 user data or .bashrc (never commit)
export TAILSCALE_AUTH_KEY="tskey-auth-REAL_KEY_HERE"

# Use in scripts
sudo tailscale up --authkey="${TAILSCALE_AUTH_KEY}"
```

### GitHub Secrets (for CI/CD)

```bash
# Add to GitHub repository secrets
# Settings > Secrets and variables > Actions > New repository secret

Name: TAILSCALE_AUTH_KEY
Value: tskey-auth-REAL_KEY_HERE

# Use in workflows
- name: Setup Tailscale
  env:
    TAILSCALE_KEY: ${{ secrets.TAILSCALE_AUTH_KEY }}
  run: |
    sudo tailscale up --authkey="${TAILSCALE_KEY}"
```

## Verification Checklist

Before committing any file that mentions Tailscale:

- [ ] Search file for `tskey-` patterns
- [ ] Verify all keys are placeholder examples
- [ ] Check no real 48-52 character keys present
- [ ] Confirm `.gitignore` blocks real keys
- [ ] Run: `git diff` to review changes
- [ ] Run: `git secrets --scan` if installed

## Questions?

If you're unsure whether a key is safe to commit, **don't commit it**.

Ask your team lead or security engineer (Sheniese/Cuong) for review.

**When in doubt, treat it as sensitive and use Secrets Manager.**

---

**Remember:** One exposed key can compromise your entire infrastructure. Better safe than sorry.

