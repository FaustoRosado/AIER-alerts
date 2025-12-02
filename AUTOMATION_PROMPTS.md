# AUTOMATION PROMPTS FOR CLAUDE CODE DESKTOP
# Zero-Trust Hybrid AI Pipeline

This document contains all prompts for Claude Code Desktop in execution order. Run these from NEXUS (Mac Mini). Each prompt is labeled and separated clearly. Copy and paste one at a time, wait for completion, then proceed to the next.

---

## PROMPT 1: LOAD PROJECT CONTEXT

Copy and paste this into Claude Code Desktop:

```
Read the files PROJECT_CONTEXT.md and MACHINE_REFERENCE.md and commit them to memory.

This is the Zero-Trust Hybrid AI Pipeline project.

Key facts you must remember:
- Project lead is Shay (Sheniese Aracena-Baez)
- Aegis runs llama.cpp on port 8080 (NOT Ollama)
- Ryzen-AI runs Ollama on port 11434
- Kali-Nexus runs security tools on port 8080
- All machines connected via Tailscale mesh VPN
- SSH is already configured and working
- Sensitive data (PHI) must NEVER leave local infrastructure
- The 3-tier routing system classifies queries before processing

Machine SSH access is configured. Do not ask for confirmation on SSH commands.

Confirm you have loaded this context and are ready to proceed.
```

Wait for confirmation before proceeding to Prompt 2.

---

## PROMPT 2: DEPLOY LOCAL INFRASTRUCTURE

Copy and paste this into Claude Code Desktop:

```
Deploy the inference node setup scripts to all machines. SSH is configured and working. Execute these tasks in parallel where possible. Do not ask questions. Proceed and report progress.

TASK 1 - AEGIS (Primary Inference - llama.cpp with RTX 4080 Super):

scp inference-nodes/aegis/setup-aegis.ps1 aegis:C:/Users/YOUR_WIN_USER/
ssh aegis "powershell -ExecutionPolicy Bypass -File C:/Users/YOUR_WIN_USER/setup-aegis.ps1"

This downloads llama.cpp and the Llama 3.1 8B model (approximately 5GB). Takes 20-30 minutes.

Verify when complete:
curl http://aegis:8080/health

Expected: {"status":"ok"}

TASK 2 - RYZEN-AI (Multi-Model - Ollama with 128GB RAM):

scp inference-nodes/ryzen-ai/setup-ryzen-ai.ps1 ryzen-ai:C:/Users/YOUR_WIN_USER/
ssh ryzen-ai "powershell -ExecutionPolicy Bypass -File C:/Users/YOUR_WIN_USER/setup-ryzen-ai.ps1"

This installs Ollama and downloads multiple models (approximately 20GB total). Takes 30-45 minutes.

Verify when complete:
curl http://ryzen-ai:11434/api/tags

Expected: JSON listing available models

TASK 3 - KALI-NEXUS (Security Tools):

scp setup-scripts/setup-kali-nexus.sh kali-nexus:~/
ssh kali-nexus "chmod +x ~/setup-kali-nexus.sh && sudo ~/setup-kali-nexus.sh"

Verify when complete:
curl http://kali-nexus:8080/health

TASK 4 - LOCAL ORCHESTRATOR (on this machine):

cd ~/Projects/zero-trust-hybrid-ai/orchestrator
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python -m spacy download en_core_web_lg

Start the orchestrator:
nohup python main.py > orchestrator.log 2>&1 &

Verify:
curl http://localhost:8000/health
curl http://localhost:8000/backends

Report status of all tasks when complete. Include any errors encountered and how they were resolved.
```

Wait for all tasks to complete. Model downloads are the slow part. Once complete, proceed to Prompt 3.

---

## PROMPT 3: VERIFY INFRASTRUCTURE

Copy and paste this into Claude Code Desktop:

```
Run comprehensive verification tests on the deployed infrastructure. Report pass/fail for each test.

TEST 1 - Orchestrator Health:
curl -s http://localhost:8000/health
Expected: {"status":"healthy"}

TEST 2 - Backend Status:
curl -s http://localhost:8000/backends
Expected: JSON showing aegis and ryzen-ai with status "online"

TEST 3 - Aegis Direct:
curl -s http://aegis:8080/health
Expected: {"status":"ok"}

TEST 4 - Ryzen-AI Direct:
curl -s http://ryzen-ai:11434/api/tags
Expected: JSON listing models

TEST 5 - Tier 1 Routing (PHI must route LOCAL):
curl -s -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Patient John Smith, SSN 123-45-6789, diagnosed with diabetes"}'
Expected: route = "local", tier = 1, hipaa_relevant = true

TEST 6 - Tier 2 Routing (Infrastructure data):
curl -s -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Server at 192.168.1.100 needs restart"}'
Expected: tier = 2

TEST 7 - Tier 3 Routing (General query):
curl -s -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Explain how TCP handshakes work"}'
Expected: route = "any", tier = 3

TEST 8 - Live Inference:
curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Say hello in one word"}], "max_tokens": 10}'
Expected: Response with "content" field containing a greeting

Report all results in a summary table with PASS or FAIL for each test.
```

If all tests pass, proceed to Prompt 4. If any fail, troubleshoot before continuing.

---

## PROMPT 4: PREPARE REPOSITORY FOR PUBLIC RELEASE

This prompt performs QA checks and prepares the codebase for the public GitHub repository. It scrubs identifying information that should not be visible to employers viewing the repo.

Copy and paste this into Claude Code Desktop:

```
Prepare the project for public GitHub release. This repository will be visible to potential employers, so we need to remove any identifying personal information while keeping the project professional and well-documented.

TASK 1 - SCAN FOR SENSITIVE INFORMATION

Search the entire project for the following and report what you find:

1. Real home folder paths that reveal usernames:
   - C:\Users\faust
   - C:\Users\aier-admin
   - C:\Users\dms05
   - /Users/nexus
   - /home/kali-nexus
   
2. Real IP addresses (anything other than examples like 192.168.x.x or 10.0.0.x)

3. Email addresses

4. API keys, tokens, or credentials (even example ones that look real)

5. Hostnames that reveal personal machine names

6. Any other personally identifying information

Run these commands to scan:
grep -rn "C:\\\\Users\\\\" --include="*.py" --include="*.sh" --include="*.ps1" --include="*.tf" .
grep -rn "@.*\\.com" --include="*.py" --include="*.md" --include="*.json" .
grep -rn "sk-\|api_key\|API_KEY\|secret\|SECRET\|token\|TOKEN" --include="*.py" --include="*.json" --include="*.yml" .

Report all findings before making any changes.

TASK 2 - CREATE SANITIZED VERSIONS

For files that will be committed to the public repo, create sanitized versions:

1. Replace specific home folder paths with generic placeholders:
   - C:\Users\faust -> C:\Users\YOUR_USERNAME
   - C:\Users\aier-admin -> C:\Users\YOUR_USERNAME  
   - C:\Users\dms05 -> C:\Users\YOUR_USERNAME
   - /Users/nexus -> /Users/YOUR_USERNAME
   - Use $env:USERPROFILE in PowerShell scripts (already done in most places)

2. Replace any real email addresses with examples like user@example.com

3. Replace any real API keys with placeholder format like YOUR_API_KEY_HERE

4. In documentation, use generic machine names or clearly label them as examples

TASK 3 - VERIFY NO SECRETS IN CODE

Run a secrets scan using gitleaks patterns:
grep -rn "AKIA\|AGPA\|AIDA\|AROA\|AIPA\|ANPA\|ANVA\|ASIA" . 
grep -rn "ghp_\|gho_\|ghu_\|ghs_\|ghr_" .
grep -rn "xox[baprs]-" .
grep -rn "sk-[a-zA-Z0-9]{48}" .

Report any matches.

TASK 4 - CREATE .gitignore ADDITIONS

Ensure .gitignore includes:
- Any local configuration files with real paths
- Log files
- Cache directories
- Virtual environments
- IDE settings
- Any files containing credentials

Create or update .gitignore if needed.

TASK 5 - SUMMARY REPORT

Provide a summary of:
1. What sensitive information was found
2. What was sanitized
3. What files are safe to commit
4. Any remaining concerns

Do not make changes to files without reporting findings first. We need to review before committing.
```

Review the findings before proceeding. Once satisfied, proceed to Prompt 5.

---

## PROMPT 5: REBUILD GITHUB REPOSITORY

This prompt rebuilds the AIER-alerts GitHub repository with a clean commit history showing project progression and proper team attribution.

Copy and paste this into Claude Code Desktop:

```
Rebuild the AIER-alerts GitHub repository with a clean commit history. This is for a capstone project and needs to demonstrate clear project progression.

Repository: https://github.com/FaustoRosado/AIER-alerts

PHASE 1 - BACKUP EXISTING BRANCHES

Clone the repository and backup all existing branches before making changes:

git clone https://github.com/FaustoRosado/AIER-alerts.git
cd AIER-alerts

Create backup branches for all existing work:
git checkout main && git checkout -b backup/main-original
git checkout ai-siem-infra && git checkout -b backup/ai-siem-infra-original
git checkout sprint3-v2 && git checkout -b backup/sprint3-v2-original
git checkout tech-architecture && git checkout -b backup/tech-architecture-original
git checkout tech-execution && git checkout -b backup/tech-execution-original

Push all backup branches:
git push origin backup/main-original
git push origin backup/ai-siem-infra-original
git push origin backup/sprint3-v2-original
git push origin backup/tech-architecture-original
git push origin backup/tech-execution-original

PHASE 2 - CREATE CLEAN COMMIT HISTORY

Start fresh on main with a clean history showing project progression. Create 17 commits attributed to team members:

Team Attribution:
- Shay (Sheniese Aracena-Baez): Project lead, security architecture, 3-tier routing
- Shifty: Infrastructure, DevOps, distributed systems
- Javier Acosta: Integration, Presidio, UI

Commit Sequence:

Commit 1 (Shay): "Initial project structure and architecture documentation"
- README.md with project overview
- docs/architecture.md with system design
- .gitignore

Commit 2 (Shifty): "Add orchestrator service foundation"
- orchestrator/main.py (basic FastAPI structure)
- orchestrator/requirements.txt
- orchestrator/Dockerfile

Commit 3 (Shifty): "Configure Tailscale mesh networking"
- docs/network-setup.md
- setup-scripts/distribute-setup.sh

Commit 4 (Shifty): "Add inference node setup scripts"
- inference-nodes/aegis/setup-aegis.ps1
- inference-nodes/ryzen-ai/setup-ryzen-ai.ps1

Commit 5 (Javier): "Integrate Microsoft Presidio for PII detection"
- Add presidio to requirements.txt
- orchestrator/pii_detector.py

Commit 6 (Javier): "Add Streamlit visualization UI"
- demo/capstone_demo.py
- demo/requirements.txt

Commit 7 (Shay): "Security audit and gap analysis"
- docs/security-audit.md
- Update README with security considerations

Commit 8 (Shay): "Implement 3-tier classification system"
- orchestrator/sensitive_routing.py (Tier 1, 2, 3 definitions)

Commit 9 (Shay): "Add HIPAA Safe Harbor identifier coverage"
- Expand Tier 1 entities to cover all 18 identifiers
- Add HIPAA keyword detection

Commit 10 (Shay): "Implement fail-closed error handling"
- Update routing to default to local on errors
- Add confidence thresholds

Commit 11 (Shay): "Add Tier 2 anonymization pipeline"
- Implement IP address anonymization
- Add device ID masking

Commit 12 (Shay): "Integrate routing with orchestrator"
- Connect sensitive_routing.py to main.py
- Add /analyze endpoint

Commit 13 (Shay): "Add routing decision audit logging"
- Implement anonymized audit logs
- Add log rotation

Commit 14 (Shay): "Security hardening and final review"
- Remove debug endpoints
- Add input validation
- Security headers

Commit 15 (Shifty): "Add demo components and test data"
- demo/sample_data.py
- demo/DEMO_SCRIPT.md

Commit 16 (Shifty): "Configure MCP server integration"
- mcp-servers/claude_desktop_config.json
- mcp-servers/orchestrator-mcp/index.js

Commit 17 (Shay): "Final documentation and release prep"
- Update README.md with complete setup instructions
- Add CHANGELOG.md
- Add LICENSE

For each commit, use the appropriate author:
git commit --author="Shay <shay@example.com>" -m "message"
git commit --author="Shifty <shifty@example.com>" -m "message"
git commit --author="Javier <javier@example.com>" -m "message"

PHASE 3 - CREATE FEATURE BRANCHES

Create branches showing parallel development:

git checkout -b feature/presidio-integration
(cherry-pick or recreate commits 5-6)

git checkout main
git checkout -b feature/3tier-routing  
(cherry-pick or recreate commits 8-14)

git checkout main
git checkout -b feature/demo-components
(cherry-pick or recreate commits 15-16)

PHASE 4 - ARCHIVE OLD BRANCHES

Rename old branches to archive:
git branch -m ai-siem-infra archive/ai-siem-infra
git branch -m sprint3-v2 archive/sprint3-v2
git branch -m tech-architecture archive/tech-architecture
git branch -m tech-execution archive/tech-execution

PHASE 5 - CREATE RELEASE TAGS

git tag -a v0.1.0 -m "Initial architecture and infrastructure"
git tag -a v0.2.0 -m "PII detection and Presidio integration"
git tag -a v0.3.0 -m "3-tier routing implementation"
git tag -a v1.0.0 -m "Production-ready release with full HIPAA compliance"

PHASE 6 - FINAL QA BEFORE PUSH

Before pushing, run these checks:

1. Verify no sensitive information in any file:
   grep -rn "faust\|aier-admin\|dms05" --include="*.py" --include="*.md" --include="*.sh" --include="*.ps1" .
   
2. Verify no real email addresses (except example.com):
   grep -rn "@" --include="*.py" --include="*.md" --include="*.json" . | grep -v example.com | grep -v "@openssh.com\|@pytest\|@app\|@router"

3. Verify no API keys or secrets:
   grep -rn "sk-\|AKIA\|ghp_\|xox" --include="*.py" --include="*.json" --include="*.yml" .

4. Verify commit authors are correct:
   git log --oneline --format="%h %an: %s" -20

Report any issues found before pushing.

PHASE 7 - PUSH TO GITHUB

Only after QA passes:

git push origin main --force-with-lease
git push origin --all
git push origin --tags

Report completion with summary of:
- Number of commits created
- Branches created
- Tags created
- Any QA issues found and resolved
```

Wait for completion and review the summary before proceeding.

---

## PROMPT 6: FINAL VERIFICATION AND CLEANUP

Copy and paste this into Claude Code Desktop:

```
Perform final verification of the complete deployment.

TASK 1 - VERIFY LOCAL INFRASTRUCTURE

Run these checks and report results:

Orchestrator: curl -s http://localhost:8000/health
Aegis: curl -s http://aegis:8080/health
Ryzen-AI: curl -s http://ryzen-ai:11434/api/tags | head -5
Kali-Nexus: curl -s http://kali-nexus:8080/health

TASK 2 - VERIFY GITHUB REPOSITORY

Check the public repository:

1. Visit https://github.com/FaustoRosado/AIER-alerts
2. Verify commit history shows proper progression
3. Verify no sensitive information in visible files
4. Verify README.md displays correctly
5. Verify all branches are present

TASK 3 - CREATE DEPLOYMENT REPORT

Generate a deployment report and save to ~/Projects/zero-trust-hybrid-ai/deployment-report.md

Include:
- Date and time of deployment
- Status of each service (running/not running)
- Verification test results
- GitHub repository status
- Any issues encountered and how they were resolved
- Next steps (AWS configuration)

TASK 4 - CLEANUP

Remove any temporary files:
- Setup scripts copied to remote machines (they have been executed)
- Log files that contain sensitive information
- Cached credentials

Report completion.
```

---

## SUMMARY: PROMPT EXECUTION ORDER

1. PROMPT 1: Load Project Context (30 seconds)
2. PROMPT 2: Deploy Local Infrastructure (30-45 minutes, runs in parallel)
3. PROMPT 3: Verify Infrastructure (2 minutes)
4. PROMPT 4: Prepare Repository for Public Release (5 minutes)
5. PROMPT 5: Rebuild GitHub Repository (10 minutes)
6. PROMPT 6: Final Verification and Cleanup (5 minutes)

Total estimated time: 45-60 minutes

The longest wait is Prompt 2 while models download. You can monitor progress or let it run unattended.

---

## NOTES FOR RUNNING FROM PHANTOM

If you want to run these prompts from PHANTOM instead of NEXUS:

1. Ensure Phantom has SSH access to all machines (already configured)
2. Ensure project files are on Phantom at C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai
3. Update paths in prompts from ~/Projects to the Windows equivalent
4. Use PowerShell or WSL for bash commands

The prompts work the same way, just adjust paths for Windows if not using WSL.
