# AUTOMATION PROMPTS FOR CLAUDE CODE DESKTOP (PHANTOM)
# Zero-Trust Hybrid AI Pipeline
# Run these from PHANTOM (Dell XPS) instead of NEXUS

# NOTE ON SYNCING PROJECT FILES BETWEEN MACHINES:
# Use git push/pull when switching between NEXUS and PHANTOM.
# Before leaving a machine: git add . && git commit -m "WIP" && git push
# When arriving on other machine: git pull
# This keeps both copies in sync. The orchestrator always runs on NEXUS
# regardless of which machine you are controlling from.

---

## PROMPT 1: LOAD PROJECT CONTEXT

Copy and paste this into Claude Code Desktop on PHANTOM:

```
Read the files PROJECT_CONTEXT.md and MACHINE_REFERENCE.md and commit them to memory.

This is the Zero-Trust Hybrid AI Pipeline project.

Key facts you must remember:
- Project lead is Shay (Sheniese Aracena-Baez)
- Aegis runs llama.cpp on port 8080 (NOT Ollama)
- Ryzen-AI runs Ollama on port 11434
- Kali-Nexus runs security tools on port 8080
- The orchestrator runs on NEXUS (not on this machine)
- All machines connected via Tailscale mesh VPN
- SSH is already configured and working from PHANTOM to all machines
- Sensitive data (PHI) must NEVER leave local infrastructure

Machine SSH access is configured. Do not ask for confirmation on SSH commands.

I am running Claude Code Desktop from PHANTOM (Windows), not NEXUS.
The project is located at C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai

Confirm you have loaded this context and are ready to proceed.
```

Wait for confirmation before proceeding to Prompt 2.

---

## PROMPT 2: DEPLOY LOCAL INFRASTRUCTURE (FROM PHANTOM)

Copy and paste this into Claude Code Desktop on PHANTOM:

```
Deploy the inference node setup scripts to all machines. SSH is configured and working from PHANTOM. Execute these tasks in parallel where possible. Do not ask questions. Proceed and report progress.

I am running from PHANTOM (Windows). The project path is C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai

TASK 1 - AEGIS (Primary Inference - llama.cpp with RTX 4080 Super):

scp C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai\inference-nodes\aegis\setup-aegis.ps1 aegis:C:/Users/YOUR_WIN_USER/
ssh aegis "powershell -ExecutionPolicy Bypass -File C:/Users/YOUR_WIN_USER/setup-aegis.ps1"

This downloads llama.cpp and the Llama 3.1 8B model (approximately 5GB). Takes 20-30 minutes.

Verify when complete:
curl http://aegis:8080/health

Expected: {"status":"ok"}

TASK 2 - RYZEN-AI (Multi-Model - Ollama with 128GB RAM):

scp C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai\inference-nodes\ryzen-ai\setup-ryzen-ai.ps1 ryzen-ai:C:/Users/YOUR_WIN_USER/
ssh ryzen-ai "powershell -ExecutionPolicy Bypass -File C:/Users/YOUR_WIN_USER/setup-ryzen-ai.ps1"

This installs Ollama and downloads multiple models (approximately 20GB total). Takes 30-45 minutes.

Verify when complete:
curl http://ryzen-ai:11434/api/tags

Expected: JSON listing available models

TASK 3 - KALI-NEXUS (Security Tools):

scp C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai\setup-scripts\setup-kali-nexus.sh kali-nexus:~/
ssh kali-nexus "chmod +x ~/setup-kali-nexus.sh && sudo ~/setup-kali-nexus.sh"

Verify when complete:
curl http://kali-nexus:8080/health

TASK 4 - ORCHESTRATOR ON NEXUS (remote setup via SSH):

The orchestrator runs on NEXUS, not on PHANTOM. Set it up remotely:

First, copy project files to NEXUS if not already there:
scp -r C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai nexus:~/Projects/

Then set up and start the orchestrator:
ssh nexus "cd ~/Projects/zero-trust-hybrid-ai/orchestrator && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python -m spacy download en_core_web_lg && nohup python main.py > orchestrator.log 2>&1 &"

Verify:
curl http://nexus:8000/health
curl http://nexus:8000/backends

Report status of all tasks when complete. Include any errors encountered and how they were resolved.
```

Wait for all tasks to complete. Model downloads are the slow part. Once complete, proceed to Prompt 3.

---

## PROMPT 3: VERIFY INFRASTRUCTURE (FROM PHANTOM)

Copy and paste this into Claude Code Desktop on PHANTOM:

```
Run comprehensive verification tests on the deployed infrastructure. Report pass/fail for each test.

I am running from PHANTOM. All services are accessed via Tailscale hostnames.

TEST 1 - Orchestrator Health (on NEXUS):
curl -s http://nexus:8000/health
Expected: {"status":"healthy"}

TEST 2 - Backend Status:
curl -s http://nexus:8000/backends
Expected: JSON showing aegis and ryzen-ai with status "online"

TEST 3 - Aegis Direct:
curl -s http://aegis:8080/health
Expected: {"status":"ok"}

TEST 4 - Ryzen-AI Direct:
curl -s http://ryzen-ai:11434/api/tags
Expected: JSON listing models

TEST 5 - Tier 1 Routing (PHI must route LOCAL):
curl -s -X POST http://nexus:8000/analyze -H "Content-Type: application/json" -d "{\"text\": \"Patient John Smith, SSN 123-45-6789, diagnosed with diabetes\"}"
Expected: route = "local", tier = 1, hipaa_relevant = true

TEST 6 - Tier 2 Routing (Infrastructure data):
curl -s -X POST http://nexus:8000/analyze -H "Content-Type: application/json" -d "{\"text\": \"Server at 192.168.1.100 needs restart\"}"
Expected: tier = 2

TEST 7 - Tier 3 Routing (General query):
curl -s -X POST http://nexus:8000/analyze -H "Content-Type: application/json" -d "{\"text\": \"Explain how TCP handshakes work\"}"
Expected: route = "any", tier = 3

TEST 8 - Live Inference:
curl -s -X POST http://nexus:8000/v1/chat/completions -H "Content-Type: application/json" -d "{\"messages\": [{\"role\": \"user\", \"content\": \"Say hello in one word\"}], \"max_tokens\": 10}"
Expected: Response with "content" field containing a greeting

Report all results in a summary table with PASS or FAIL for each test.
```

If all tests pass, proceed to Prompt 4. If any fail, troubleshoot before continuing.

---

## PROMPT 4: PREPARE REPOSITORY FOR PUBLIC RELEASE (FROM PHANTOM)

Copy and paste this into Claude Code Desktop on PHANTOM:

```
Prepare the project for public GitHub release. This repository will be visible to potential employers, so we need to remove any identifying personal information while keeping the project professional.

I am running from PHANTOM. The project path is C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai

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

Run these scans:
findstr /s /i "C:\\Users\\" *.py *.sh *.ps1 *.tf *.md
findstr /s /i "@.*\.com" *.py *.md *.json
findstr /s /i "sk- api_key API_KEY secret SECRET token TOKEN" *.py *.json *.yml

Report all findings before making any changes.

TASK 2 - CREATE SANITIZED VERSIONS

For files that will be committed to the public repo, create sanitized versions:

1. Replace specific home folder paths with generic placeholders:
   - C:\Users\faust -> C:\Users\YOUR_USERNAME
   - C:\Users\aier-admin -> C:\Users\YOUR_USERNAME  
   - C:\Users\dms05 -> C:\Users\YOUR_USERNAME
   - /Users/nexus -> /Users/YOUR_USERNAME
   - Use $env:USERPROFILE in PowerShell scripts

2. Replace any real email addresses with examples like user@example.com

3. Replace any real API keys with placeholder format like YOUR_API_KEY_HERE

TASK 3 - VERIFY NO SECRETS IN CODE

Run a secrets scan:
findstr /s /i "AKIA AGPA AIDA AROA" *.*
findstr /s /i "ghp_ gho_ ghu_ ghs_" *.*
findstr /s /i "xox" *.*

Report any matches.

TASK 4 - CREATE .gitignore ADDITIONS

Ensure .gitignore includes:
- Any local configuration files with real paths
- Log files
- Cache directories
- Virtual environments
- IDE settings

TASK 5 - SUMMARY REPORT

Provide a summary of:
1. What sensitive information was found
2. What was sanitized
3. What files are safe to commit
4. Any remaining concerns

Do not make changes to files without reporting findings first.
```

Review the findings before proceeding. Once satisfied, proceed to Prompt 5.

---

## PROMPT 5: REBUILD GITHUB REPOSITORY (FROM PHANTOM)

Copy and paste this into Claude Code Desktop on PHANTOM:

```
Rebuild the AIER-alerts GitHub repository with a clean commit history.

Repository: https://github.com/FaustoRosado/AIER-alerts

I am running from PHANTOM. Use PowerShell-compatible commands where possible.

PHASE 1 - BACKUP EXISTING BRANCHES

Clone the repository and backup all existing branches:

git clone https://github.com/FaustoRosado/AIER-alerts.git
cd AIER-alerts

Create backup branches:
git checkout main
git checkout -b backup/main-original
git checkout ai-siem-infra
git checkout -b backup/ai-siem-infra-original
git checkout sprint3-v2
git checkout -b backup/sprint3-v2-original
git checkout tech-architecture
git checkout -b backup/tech-architecture-original
git checkout tech-execution
git checkout -b backup/tech-execution-original

Push all backup branches:
git push origin backup/main-original
git push origin backup/ai-siem-infra-original
git push origin backup/sprint3-v2-original
git push origin backup/tech-architecture-original
git push origin backup/tech-execution-original

PHASE 2 - CREATE CLEAN COMMIT HISTORY

Start fresh on main. Create 17 commits attributed to team members:

Team Attribution:
- Shay (Sheniese Aracena-Baez): Project lead, security architecture
- Shifty: Infrastructure, DevOps
- Javier Acosta: Integration, UI

Commit Sequence:

Commit 1 (Shay): "Initial project structure and architecture documentation"
Commit 2 (Shifty): "Add orchestrator service foundation"
Commit 3 (Shifty): "Configure Tailscale mesh networking"
Commit 4 (Shifty): "Add inference node setup scripts"
Commit 5 (Javier): "Integrate Microsoft Presidio for PII detection"
Commit 6 (Javier): "Add Streamlit visualization UI"
Commit 7 (Shay): "Security audit and gap analysis"
Commit 8 (Shay): "Implement 3-tier classification system"
Commit 9 (Shay): "Add HIPAA Safe Harbor identifier coverage"
Commit 10 (Shay): "Implement fail-closed error handling"
Commit 11 (Shay): "Add Tier 2 anonymization pipeline"
Commit 12 (Shay): "Integrate routing with orchestrator"
Commit 13 (Shay): "Add routing decision audit logging"
Commit 14 (Shay): "Security hardening and final review"
Commit 15 (Shifty): "Add demo components and test data"
Commit 16 (Shifty): "Configure MCP server integration"
Commit 17 (Shay): "Final documentation and release prep"

Use appropriate author for each:
git commit --author="Shay <shay@example.com>" -m "message"
git commit --author="Shifty <shifty@example.com>" -m "message"
git commit --author="Javier <javier@example.com>" -m "message"

PHASE 3 - CREATE FEATURE BRANCHES

git checkout -b feature/presidio-integration
git checkout main
git checkout -b feature/3tier-routing
git checkout main
git checkout -b feature/demo-components

PHASE 4 - ARCHIVE OLD BRANCHES

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

Before pushing, verify no sensitive information:

findstr /s /i "faust aier-admin dms05" *.py *.md *.sh *.ps1
findstr /s /i "@" *.py *.md *.json | findstr /v "example.com" | findstr /v "@openssh @pytest @app @router"
findstr /s /i "sk- AKIA ghp_ xox" *.py *.json *.yml

Verify commit authors:
git log --oneline --format="%h %an: %s" -20

Report any issues found before pushing.

PHASE 7 - PUSH TO GITHUB

Only after QA passes:

git push origin main --force-with-lease
git push origin --all
git push origin --tags

Report completion with summary.
```

---

## PROMPT 6: FINAL VERIFICATION AND CLEANUP (FROM PHANTOM)

Copy and paste this into Claude Code Desktop on PHANTOM:

```
Perform final verification of the complete deployment.

I am running from PHANTOM.

TASK 1 - VERIFY LOCAL INFRASTRUCTURE

Orchestrator: curl -s http://nexus:8000/health
Aegis: curl -s http://aegis:8080/health
Ryzen-AI: curl -s http://ryzen-ai:11434/api/tags
Kali-Nexus: curl -s http://kali-nexus:8080/health

TASK 2 - VERIFY GITHUB REPOSITORY

1. Visit https://github.com/FaustoRosado/AIER-alerts
2. Verify commit history shows proper progression
3. Verify no sensitive information in visible files
4. Verify README.md displays correctly

TASK 3 - CREATE DEPLOYMENT REPORT

Generate a deployment report and save to C:\Users\YOUR_WIN_USER\Projects\zero-trust-hybrid-ai\deployment-report.md

Include:
- Date and time of deployment
- Status of each service
- Verification test results
- GitHub repository status
- Any issues encountered
- Next steps (AWS configuration)

TASK 4 - CLEANUP

Remove temporary files and logs containing sensitive information.

Report completion.
```

---

## QUICK REFERENCE: MANAGING ORCHESTRATOR FROM PHANTOM

Start orchestrator on NEXUS:
```powershell
ssh nexus "cd ~/Projects/zero-trust-hybrid-ai/orchestrator && source venv/bin/activate && nohup python main.py > orchestrator.log 2>&1 &"
```

Stop orchestrator on NEXUS:
```powershell
ssh nexus "pkill -f 'python main.py'"
```

Check orchestrator logs:
```powershell
ssh nexus "tail -50 ~/Projects/zero-trust-hybrid-ai/orchestrator/orchestrator.log"
```

Check if orchestrator is running:
```powershell
ssh nexus "pgrep -f 'python main.py'"
```

---

## SUMMARY: PROMPT EXECUTION ORDER

1. PROMPT 1: Load Project Context (30 seconds)
2. PROMPT 2: Deploy Local Infrastructure (30-45 minutes)
3. PROMPT 3: Verify Infrastructure (2 minutes)
4. PROMPT 4: Prepare Repository for Public Release (5 minutes)
5. PROMPT 5: Rebuild GitHub Repository (10 minutes)
6. PROMPT 6: Final Verification and Cleanup (5 minutes)

Total estimated time: 45-60 minutes
