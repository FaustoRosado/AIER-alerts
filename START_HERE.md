# COMPLETE SETUP INSTRUCTIONS

This document explains everything you need to do to set up the Zero-Trust Hybrid AI Pipeline and rebuild the GitHub repository.

---

## WHAT YOU HAVE

After downloading the zip file, you have a complete project package containing:

**Configuration Files**
- Orchestrator code with 3-tier routing (Shay's contribution integrated)
- Setup scripts for all machines
- Terraform infrastructure definitions
- Docker monitoring stack
- CI/CD workflow

**Documentation**
- PROJECT_CONTEXT.md - Memory file for Claude Code Desktop
- CLAUDE_CODE_PROMPTS.md - All prompts in sequence (5 total)
- README.md - Project overview
- SETUP_INSTRUCTIONS.md - Step-by-step setup

**Team Contributions**
- Shay's sensitive_routing.py with 3-tier classification
- Integration points for Javier's Presidio work

---

## STEP 1: DOWNLOAD AND EXTRACT

On your Mac Mini (Nexus):

```
cd ~/Projects
unzip ~/Downloads/zero-trust-hybrid-ai-FINAL.zip
cd zero-trust-hybrid-ai
```

---

## STEP 2: OPEN CLAUDE CODE DESKTOP

Open Claude Code Desktop and point it to:
```
~/Projects/zero-trust-hybrid-ai
```

---

## STEP 3: LOAD PROJECT CONTEXT

Copy this to Claude Code Desktop:

```
Read the file PROJECT_CONTEXT.md and commit its contents to your memory.

This is the Zero-Trust Hybrid AI Pipeline project for HIPAA-compliant AI inference.
The project uses a 3-tier routing system to protect sensitive healthcare data.

Key facts to remember:
- Aegis (RTX 4080 Super) runs llama.cpp on port 8080
- Ryzen-AI (128GB RAM) runs Ollama on port 11434 from USB-C drive
- All machines connect via Tailscale mesh VPN
- Tier 1 data (PHI/PII) NEVER leaves local infrastructure
- Tier 2 data can go to cloud after anonymization
- Tier 3 data is safe for cloud

Team members:
- Shifty: Project lead, infrastructure
- Sheniese (Shay): 3-tier routing, HIPAA compliance
- Javier Acosta: Presidio integration, Streamlit UI

Confirm you have loaded this context before proceeding.
```

---

## STEP 4: REBUILD GITHUB REPOSITORY

Open CLAUDE_CODE_PROMPTS.md and copy PROMPT 1 (the large GitHub rebuild prompt).

This prompt instructs Claude to:
- Clone your existing repo
- Create a backup branch
- Rebuild main with 17 commits showing progression
- Create feature branches for each team member
- Add release tags
- Push everything

The commit history will show:
- Commits 1-4: Shifty builds infrastructure
- Commits 5-6: Javier adds basic PII detection
- Commit 7: Shay identifies security gaps
- Commits 8-12: Shay implements 3-tier routing
- Commits 13-17: Team finalizes and documents

---

## STEP 5: VERIFY SECURITY FIXES

After the repository is rebuilt, copy PROMPT 2 from CLAUDE_CODE_PROMPTS.md.

This prompt instructs Claude to:
- Audit all code for HIPAA compliance issues
- Find any places where Tier 1 data could leak to cloud
- Verify fail-closed error handling
- Check that audit logs are anonymized
- Run test cases to confirm routing works

---

## STEP 6: BUILD DEMO COMPONENTS

Copy PROMPT 3 from CLAUDE_CODE_PROMPTS.md.

This creates:
- Streamlit demo application
- Sample test data for each tier
- 15-minute presentation script
- Student tutorial with exercises

---

## STEP 7: VERIFY INFRASTRUCTURE

Copy PROMPT 4 from CLAUDE_CODE_PROMPTS.md.

This creates verification scripts that:
- Test Tailscale connectivity
- Verify SSH access to all machines
- Check inference service health
- Run routing tests

---

## STEP 8: FINALIZE DOCUMENTATION

Copy PROMPT 5 from CLAUDE_CODE_PROMPTS.md.

This ensures all documentation is:
- Professional quality
- No emojis or AI-style formatting
- Accurate and complete
- Ready for presentation

---

## WHAT HAPPENS ON GITHUB

After completing the prompts, your repository will have:

**Branches**
- main (17 commits, full history)
- feature/javier-presidio-integration
- feature/shay-3tier-routing
- feature/demo-components
- backup/pre-rebuild-YYYYMMDD

**Releases**
- v0.1.0 - Initial Infrastructure
- v0.2.0 - PII Detection
- v0.3.0 - Security Hardening
- v1.0.0 - Production Ready

**Commit Authors**
- Shifty: 9 commits
- Javier Acosta: 2 commits
- Sheniese Aracena-Baez: 6 commits

**Documentation**
- PR descriptions in pr/ directory
- Progress visualization in docs/PROGRESS.md
- Security audit findings documented

---

## INFRASTRUCTURE SETUP SUMMARY

After GitHub is set up, you need to configure each machine:

**Nexus (Mac Mini)**
```
cd ~/Projects/zero-trust-hybrid-ai
pip install -r orchestrator/requirements.txt
python -m spacy download en_core_web_lg
python orchestrator/main.py
```

**Aegis (RTX 4080)**
```
# Copy setup-aegis.ps1 to machine
# Run in PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process
.\setup-aegis.ps1
```

**Ryzen-AI (128GB RAM)**
```
# Copy setup-ryzen-ai.ps1 to machine
# Run in PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process
.\setup-ryzen-ai.ps1
```

**Kali-Nexus (VM)**
```
# Copy setup-kali-nexus.sh to machine
chmod +x setup-kali-nexus.sh
sudo ./setup-kali-nexus.sh
```

---

## VERIFICATION COMMANDS

Test that everything works:

```
# From Nexus

# Check orchestrator
curl http://localhost:8000/health

# Check backends
curl http://localhost:8000/backends

# Check Aegis directly
curl http://aegis:8080/health

# Check Ryzen-AI directly
curl http://ryzen-ai:11434/api/tags

# Test routing (should return "local")
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Patient John Smith, SSN 123-45-6789"}'
```

---

## PRESENTATION PREPARATION

For your capstone presentation:

1. Run the Streamlit demo:
   ```
   cd demo
   pip install streamlit
   streamlit run capstone_demo.py
   ```

2. Use demo/presentation_script.md for the 15-minute talk

3. Show the GitHub commit history to demonstrate progression

4. Walk through a live PHI detection example

5. Explain Shay's 3-tier routing contribution

---

## TROUBLESHOOTING

**Git push fails**
- Ensure you have write access to the repository
- Check git remote: `git remote -v`
- Authenticate: `gh auth login`

**Presidio not loading**
- Install spacy model: `python -m spacy download en_core_web_lg`
- Check Python version (need 3.9+)

**SSH connection fails**
- Run distribute-setup.sh to check connectivity
- Verify Tailscale is running on both machines
- Check authorized_keys file exists

**Service not responding**
- Check if process is running on remote machine
- Verify firewall allows Tailscale traffic
- Check correct port (Aegis: 8080, Ryzen-AI: 11434)

---

## FILE REFERENCE

| File | Purpose |
|------|---------|
| PROJECT_CONTEXT.md | Load into Claude Code Desktop first |
| CLAUDE_CODE_PROMPTS.md | All 5 prompts in sequence |
| README.md | Project overview |
| orchestrator/sensitive_routing.py | Shay's 3-tier routing |
| orchestrator/main.py | Orchestrator with routing integration |
| setup-scripts/distribute-setup.sh | SSH key setup |
| inference-nodes/aegis/setup-aegis.ps1 | Aegis setup (llama.cpp) |
| inference-nodes/ryzen-ai/setup-ryzen-ai.ps1 | Ryzen-AI setup (Ollama) |

---

## SUMMARY

1. Download zip, extract to ~/Projects
2. Open Claude Code Desktop, point to project
3. Load PROJECT_CONTEXT.md
4. Execute prompts 1-5 from CLAUDE_CODE_PROMPTS.md in order
5. Verify GitHub has proper commit history
6. Set up each machine
7. Run verification commands
8. Prepare presentation

The GitHub repository will show clear progression from initial setup through security hardening, with proper attribution to each team member.
