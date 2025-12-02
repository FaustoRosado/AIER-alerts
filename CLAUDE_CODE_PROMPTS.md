# CLAUDE CODE DESKTOP - COMPLETE PROJECT PROMPTS

This document contains all prompts needed to fully implement the Zero-Trust Hybrid AI Pipeline project. Execute these prompts in order.

---

## HOW TO USE THIS DOCUMENT

1. Open Claude Code Desktop
2. Point it to your project directory
3. Copy and paste each prompt in sequence
4. Wait for completion before moving to next prompt
5. Verify results at each checkpoint

---

## PROMPT 0: INITIAL CONTEXT LOADING

Use this prompt first to establish project context:

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

## PROMPT 1: GITHUB REPOSITORY REBUILD

This prompt rebuilds the GitHub repository with proper commit history showing project progression.

```
I need you to rebuild the AIER-alerts GitHub repository to demonstrate clear project progression with meaningful commit history. This is for a capstone project and needs to show the evolution from initial concept to HIPAA-compliant implementation.

Repository: https://github.com/FaustoRosado/AIER-alerts

IMPORTANT: This rebuild must preserve authorship attribution for team members (Shifty, Shay, Javier) and show logical progression through commits.

PHASE 1: REPOSITORY ASSESSMENT AND BACKUP

The repository currently has these branches:
- main (default)
- ai-siem-infra
- sprint3-v2
- tech-architecture
- tech-execution

1. Clone the repository with all branches
   git clone https://github.com/FaustoRosado/AIER-alerts.git
   cd AIER-alerts
   git fetch --all

2. Create backup branches preserving ALL existing work
   git checkout main
   git checkout -b backup/main-$(date +%Y%m%d)
   git push origin backup/main-$(date +%Y%m%d)
   
   git checkout ai-siem-infra
   git checkout -b backup/ai-siem-infra-$(date +%Y%m%d)
   git push origin backup/ai-siem-infra-$(date +%Y%m%d)
   
   git checkout sprint3-v2
   git checkout -b backup/sprint3-v2-$(date +%Y%m%d)
   git push origin backup/sprint3-v2-$(date +%Y%m%d)
   
   git checkout tech-architecture
   git checkout -b backup/tech-architecture-$(date +%Y%m%d)
   git push origin backup/tech-architecture-$(date +%Y%m%d)
   
   git checkout tech-execution
   git checkout -b backup/tech-execution-$(date +%Y%m%d)
   git push origin backup/tech-execution-$(date +%Y%m%d)

3. Document existing commit history from each branch
   Create docs/ORIGINAL_HISTORY.md containing:
   
   git checkout main && git log --oneline -20 > main_history.txt
   git checkout ai-siem-infra && git log --oneline -20 > ai-siem-infra_history.txt
   git checkout sprint3-v2 && git log --oneline -20 > sprint3-v2_history.txt
   git checkout tech-architecture && git log --oneline -20 > tech-architecture_history.txt
   git checkout tech-execution && git log --oneline -20 > tech-execution_history.txt

4. Audit each existing branch for security issues
   Create AUDIT_FINDINGS.md documenting for EACH branch:
   - Which files exist
   - Any routing logic found
   - Where Tier 1 data could reach cloud endpoints
   - Missing HIPAA entity types
   - Fail-open error handling
   - Raw PHI in logs
   
   Pay special attention to tech-execution branch - this likely has the tier
   enforcement issues that need fixing.

PHASE 2: CLEAN MAIN BRANCH STRUCTURE

Reset main to build clean history. Create these commits in order:

COMMIT 1: "Initial project structure and documentation"
Author: Shay (Sheniese Aracena-Baez)
Files to create:
- README.md (project overview, team members, architecture summary)
- LICENSE (MIT or Apache 2.0)
- .gitignore (Python, Node, IDE files)
- docs/ARCHITECTURE.md (high-level system design)
- docs/HARDWARE_SPECS.md (machine inventory)

COMMIT 2: "Add infrastructure configuration"
Author: Shifty
Files to create:
- terraform/main.tf (AWS resources)
- terraform/variables.tf
- terraform/outputs.tf
- docker/docker-compose.yml
- docker/prometheus/prometheus.yml
- docker/grafana/dashboards/zero-trust-ai.json
- .github/workflows/ci.yml

COMMIT 3: "Add basic orchestrator without routing"
Author: Shifty
Files to create:
- orchestrator/main.py (FastAPI app, backend health checks, NO routing logic yet)
- orchestrator/requirements.txt (basic deps, NO presidio yet)
- orchestrator/Dockerfile
- tests/test_orchestrator_basic.py

COMMIT 4: "Add inference node setup scripts"
Author: Shifty
Files to create:
- inference-nodes/aegis/setup-aegis.ps1
- inference-nodes/ryzen-ai/setup-ryzen-ai.ps1
- setup-scripts/distribute-setup.sh
- setup-scripts/setup-kali-nexus.sh
- setup-scripts/setup-phantom.ps1

COMMIT 5: "Implement binary PII routing (Javier's initial approach)"
Author: Javier Acosta
Files to modify/create:
- orchestrator/pii_detection.py (simple binary: sensitive or not)
- orchestrator/main.py (add basic routing)
- orchestrator/requirements.txt (add presidio)

This represents Javier's initial contribution - binary routing.
Include comment: "Initial PII detection - routes sensitive to local, safe to cloud"

COMMIT 6: "Add Streamlit UI for PII visualization"
Author: Javier Acosta
Files to create:
- ui/app.py (Streamlit app showing detection results)
- ui/requirements.txt
- docs/UI_GUIDE.md

COMMIT 7: "SECURITY ISSUE: Identify Tier enforcement gaps"
Author: Shay (Sheniese Aracena-Baez)
Files to create:
- docs/SECURITY_AUDIT_INITIAL.md

Content should document:
"Audit of current routing implementation reveals potential HIPAA compliance issues:

1. Binary routing insufficient for healthcare use cases
   - Some data types (IP addresses, device IDs) can be anonymized for cloud
   - Current approach treats all PII equally

2. Missing HIPAA Safe Harbor identifiers
   - Medical record numbers not detected
   - Health plan IDs not detected
   - Device identifiers not detected

3. No fail-closed error handling
   - If Presidio fails, system defaults to cloud routing
   - This could expose PHI during service disruptions

4. HIPAA keyword context not considered
   - Text containing 'patient', 'diagnosis' without explicit entities
   - Should be treated as potentially sensitive

5. Audit logs contain raw text
   - PHI visible in application logs
   - Compliance violation for log aggregation

Recommended: Implement 3-tier routing system with strict enforcement."

COMMIT 8: "Implement 3-tier routing system"
Author: Shay (Sheniese Aracena-Baez)
Files to create/modify:
- orchestrator/sensitive_routing.py (complete 3-tier implementation)
- orchestrator/requirements.txt (update presidio version)
- tests/test_sensitive_routing.py

This is the core security fix. The sensitive_routing.py should include:
- Route enum (LOCAL, ANONYMIZE_CLOUD, CLOUD)
- TIER_1_ENTITIES (all HIPAA identifiers)
- TIER_2_ENTITIES (anonymizable data)
- HIPAA_KEYWORDS (context detection)
- Confidence thresholds
- Fail-closed error handling
- Anonymization for Tier 2

COMMIT 9: "Enforce LOCAL routing for Tier 1 - no exceptions"
Author: Shay (Sheniese Aracena-Baez)
Files to modify:
- orchestrator/main.py (integrate sensitive_routing, enforce routing decisions)

Key changes:
- Remove any allow_cloud override for Tier 1
- Add HIPAA keyword check as safety net
- Wrap all detection in try/except that defaults to LOCAL
- Log only anonymized text

COMMIT 10: "Add comprehensive HIPAA entity coverage"
Author: Shay (Sheniese Aracena-Baez)
Files to modify:
- orchestrator/sensitive_routing.py

Add these to TIER_1_ENTITIES:
- MEDICAL_RECORD, MRN
- HEALTH_PLAN_ID
- DEVICE_IDENTIFIER (medical devices)
- BIOMETRIC
- GENETIC_DATA
- VEHICLE_ID
- CERTIFICATE_NUMBER

COMMIT 11: "Implement fail-closed error handling"
Author: Shay (Sheniese Aracena-Baez)
Files to modify:
- orchestrator/sensitive_routing.py
- orchestrator/main.py

Add explicit try/except blocks that default to LOCAL on any failure.

COMMIT 12: "Add anonymized audit logging"
Author: Shay (Sheniese Aracena-Baez)
Files to modify:
- orchestrator/main.py
- orchestrator/sensitive_routing.py

Ensure all logging uses anonymized text only.

COMMIT 13: "Add security validation tests"
Author: Shay (Sheniese Aracena-Baez)
Files to create/modify:
- tests/test_hipaa_compliance.py
- tests/test_tier_enforcement.py
- tests/conftest.py

Tests must verify:
- All HIPAA identifiers route to LOCAL
- Presidio failure routes to LOCAL
- Exception handling routes to LOCAL
- HIPAA keywords route to LOCAL
- Audit logs contain no raw PHI

COMMIT 14: "Update documentation with security model"
Author: Shay (Sheniese Aracena-Baez)
Files to modify/create:
- README.md (add security section)
- docs/SECURITY_MODEL.md (complete security documentation)
- docs/HIPAA_COMPLIANCE.md (compliance mapping)
- SECURITY_AUDIT_FINAL.md (issues resolved)

COMMIT 15: "Add demonstration components"
Author: Shifty
Files to create:
- demo/capstone_demo.py (Streamlit demo app)
- demo/sample_data.py (test cases for each tier)
- demo/presentation_script.md
- demo/student_tutorial.md

COMMIT 16: "Add MCP server integration for Claude Desktop"
Author: Shifty
Files to create:
- mcp-servers/claude_desktop_config.json
- mcp-servers/orchestrator-mcp/index.js
- mcp-servers/orchestrator-mcp/package.json

COMMIT 17: "Final documentation and project context"
Author: Shay (Sheniese Aracena-Baez)
Files to create:
- PROJECT_CONTEXT.md
- CLAUDE_CODE_PROMPT.md
- CONTRIBUTING.md
- CHANGELOG.md

PHASE 3: REORGANIZE EXISTING BRANCHES

The existing branches need to be reorganized to show clear progression.
Map the old branches to the new structure:

BRANCH MAPPING:
- ai-siem-infra → Keep as historical, represents early infrastructure work
- tech-architecture → Keep as historical, represents design phase
- sprint3-v2 → Merge relevant content into main, then archive
- tech-execution → This likely has the HIPAA issues, fix and merge into main

1. Update main branch with clean commit history
   git checkout main
   
   Now add the 17 commits as specified in PHASE 2, but PRESERVE existing
   commits by rebasing on top of them rather than force-pushing.
   
   If main has existing valuable commits, use:
   git rebase --onto main~N main~N main
   
   Or create commits that BUILD ON existing work rather than replacing it.

2. Create new feature branches showing team contributions
   
   git checkout main
   git checkout -b feature/javier-presidio-integration
   # Cherry-pick or recreate Javier's commits (5-6 from the plan)
   git push origin feature/javier-presidio-integration
   
   git checkout main  
   git checkout -b feature/shay-3tier-routing
   # Add Shay's security audit and 3-tier implementation (commits 7-12)
   git push origin feature/shay-3tier-routing
   
   git checkout main
   git checkout -b feature/demo-components
   # Add demo and presentation materials (commit 15)
   git push origin feature/demo-components

3. Fix the tech-execution branch
   git checkout tech-execution
   
   AUDIT THIS BRANCH CAREFULLY for:
   - Any code that allows Tier 1 data to reach cloud
   - Missing LOCAL enforcement
   - Fail-open error handling
   
   Apply fixes:
   - Add sensitive_routing.py with 3-tier system
   - Update main.py to enforce LOCAL for Tier 1
   - Add fail-closed error handling
   - Ensure audit logs are anonymized
   
   Commit with message: "Fix HIPAA compliance issues in tier execution"
   Author: Shay (Sheniese Aracena-Baez)
   
   git push origin tech-execution

4. Archive old branches with clear naming
   git branch -m ai-siem-infra archive/ai-siem-infra
   git branch -m tech-architecture archive/tech-architecture  
   git branch -m sprint3-v2 archive/sprint3-v2
   
   Push the renamed branches:
   git push origin archive/ai-siem-infra
   git push origin archive/tech-architecture
   git push origin archive/sprint3-v2
   
   Delete the old branch names from remote:
   git push origin --delete ai-siem-infra
   git push origin --delete tech-architecture
   git push origin --delete sprint3-v2

5. Final branch structure should be:
   
   ACTIVE BRANCHES:
   - main (default, 17+ commits showing full progression)
   - tech-execution (fixed, ready to merge)
   - feature/javier-presidio-integration
   - feature/shay-3tier-routing
   - feature/demo-components
   
   ARCHIVED BRANCHES:
   - archive/ai-siem-infra
   - archive/tech-architecture
   - archive/sprint3-v2
   
   BACKUP BRANCHES:
   - backup/main-YYYYMMDD
   - backup/ai-siem-infra-YYYYMMDD
   - backup/sprint3-v2-YYYYMMDD
   - backup/tech-architecture-YYYYMMDD
   - backup/tech-execution-YYYYMMDD

PHASE 4: CREATE PULL REQUEST DOCUMENTATION

Create PR descriptions as markdown files in pr/ directory:

pr/PR-001-presidio-integration.md
pr/PR-002-security-audit.md
pr/PR-003-3tier-routing.md

PHASE 5: GENERATE PROGRESS VISUALIZATION

Create docs/PROGRESS.md with timeline, commit summary, and security improvements comparison.

PHASE 6: PUSH ALL CHANGES

1. Push main branch
   git checkout main
   git push origin main --force-with-lease

2. Push feature branches
   git push origin feature/javier-presidio-integration
   git push origin feature/shay-3tier-routing
   git push origin feature/demo-components

3. Push fixed tech-execution branch
   git checkout tech-execution
   git push origin tech-execution --force-with-lease

4. Push archived branches (renamed from originals)
   git push origin archive/ai-siem-infra
   git push origin archive/tech-architecture
   git push origin archive/sprint3-v2

5. Delete old branch names from remote AFTER backups confirmed
   git push origin --delete ai-siem-infra
   git push origin --delete tech-architecture
   git push origin --delete sprint3-v2

6. Verify backup branches exist on remote
   git branch -r | grep backup

PHASE 7: CREATE GITHUB RELEASES

v0.1.0 - "Initial Infrastructure" (tag at commit 4)
v0.2.0 - "PII Detection" (tag at commit 6)
v0.3.0 - "Security Hardening" (tag at commit 12)
v1.0.0 - "Production Ready" (tag at commit 17)

VERIFICATION CHECKLIST

After completing all phases, verify:

COMMIT HISTORY:
[ ] Main branch shows logical progression of commits
[ ] Existing valuable commits from original branches preserved
[ ] New commits build on existing work
[ ] Each commit has appropriate author attribution

BRANCH STRUCTURE:
[ ] main - default branch with full project
[ ] tech-execution - fixed and ready for merge
[ ] feature/javier-presidio-integration - Javier's work
[ ] feature/shay-3tier-routing - Shay's security fixes
[ ] feature/demo-components - demonstration materials
[ ] archive/ai-siem-infra - historical branch preserved
[ ] archive/tech-architecture - historical branch preserved
[ ] archive/sprint3-v2 - historical branch preserved
[ ] backup/* branches exist for all original branches

SECURITY:
[ ] All Tier 1 test cases route to LOCAL
[ ] Fail-closed error handling implemented
[ ] No raw PHI in any logs or commits
[ ] HIPAA keyword detection active

DOCUMENTATION:
[ ] PR documentation exists in pr/ directory
[ ] Progress visualization in docs/PROGRESS.md
[ ] Original branch history documented in docs/ORIGINAL_HISTORY.md
[ ] README accurately describes current state
[ ] CHANGELOG documents all versions

RELEASES:
[ ] v0.1.0 tag exists
[ ] v0.2.0 tag exists
[ ] v0.3.0 tag exists
[ ] v1.0.0 tag exists

Begin with Phase 1: Clone the repository and backup ALL existing branches.
```

---

## PROMPT 2: SECURITY AUDIT AND FIXES

After the repository structure is in place, use this prompt to ensure all security issues are addressed:

```
Now audit the codebase for HIPAA compliance issues and fix them.

CRITICAL CONTEXT:
This is a healthcare AI system. HIPAA violations can result in fines up to $1.5 million per incident.
The current implementation may have serious concerns about Tier 1 data potentially reaching cloud endpoints.

AUDIT TASKS:

1. FIND TIER ENFORCEMENT GAPS
   Search all Python files for:
   - Any code path where Tier 1 data could reach cloud endpoints
   - Uses of "allow_cloud=True" or similar overrides
   - Routes that bypass the sensitivity check

2. VERIFY ENTITY COVERAGE
   Check sensitive_routing.py against HIPAA 18 Safe Harbor identifiers:
   - Names
   - Geographic data smaller than state
   - Dates (DOB, admission, discharge, death)
   - Phone numbers
   - Fax numbers
   - Email addresses
   - SSN
   - Medical record numbers
   - Health plan beneficiary numbers
   - Account numbers
   - Certificate/license numbers
   - Vehicle identifiers
   - Device identifiers
   - Web URLs
   - IP addresses
   - Biometric identifiers
   - Full-face photos
   - Any other unique identifying number

3. CHECK FAIL-CLOSED HANDLING
   - What happens if Presidio fails to load?
   - What happens if entity detection throws an exception?
   - Verify system defaults to LOCAL on any error

4. AUDIT LOG REVIEW
   - Search for any logging of raw user input
   - Ensure all logs use anonymized text only

5. FIX ALL ISSUES FOUND
   Apply fixes that:
   - Enforce LOCAL routing for ALL Tier 1 data with no exceptions
   - Add any missing HIPAA identifiers
   - Implement fail-closed error handling
   - Replace raw text logging with anonymized versions

6. RUN VERIFICATION TESTS
   Test these inputs and confirm ALL route to LOCAL:
   
   "Patient John Smith needs medication"
   "SSN 123-45-6789"
   "Call 555-123-4567 about diagnosis"
   "DOB 03/15/1962"
   "Medical record MRN-12345"
   "The patient's vitals are stable"

   If any returns CLOUD or ANONYMIZE_CLOUD, the fix is incomplete.

7. COMMIT FIXES
   Create a commit for each fix with clear message explaining the security improvement.

Begin the audit now.
```

---

## PROMPT 3: DEMO AND PRESENTATION BUILD

After security is verified, use this prompt to build demonstration components:

```
Build the demonstration components for two audiences:
1. Capstone presentation (15 minutes, technical audience)
2. Student demo (educational, cybersecurity students learning IaC and cloud)

CREATE THESE FILES:

1. demo/capstone_demo.py

A Streamlit application that demonstrates:

a) LIVE PHI DETECTION
   - Text input field for user queries
   - Real-time entity detection display
   - Tier classification (1, 2, or 3) with explanation
   - Routing decision display

b) SIDE-BY-SIDE COMPARISON
   - Original text on left panel
   - Anonymized version on right panel
   - Highlighted entities showing what was detected

c) BACKEND STATUS DASHBOARD
   - Health status for each machine (Aegis, Ryzen-AI, Kali-Nexus)
   - Connection indicators
   - Response time display

d) ROUTING VISUALIZATION
   - Visual flow showing request path
   - Color coding: red for Tier 1, yellow for Tier 2, green for Tier 3

e) SAMPLE QUERIES
   - Pre-loaded examples for each tier
   - One-click execution

2. demo/sample_data.py

Test data organized by tier:

TIER_1_SAMPLES (HIGH RISK - LOCAL ONLY):
- Patient names with medical context
- SSN examples
- Medical record numbers
- Prescription information

TIER_2_SAMPLES (MEDIUM RISK - ANONYMIZE):
- IP addresses
- Device identifiers
- Employee IDs
- Ticket numbers

TIER_3_SAMPLES (SAFE - CLOUD OK):
- General technical questions
- Code help requests
- Explanations of concepts

3. demo/student_tutorial.md

A hands-on tutorial covering:

a) INFRASTRUCTURE AS CODE
   - What Terraform does and why
   - Walking through terraform/main.tf
   - Each AWS resource explained
   - How to read a Terraform plan

b) ZERO-TRUST ARCHITECTURE
   - Definition and principles
   - Why sensitive data stays local
   - Tailscale mesh networking explained
   - Defense in depth layers

c) CI/CD PIPELINE
   - GitHub Actions workflow breakdown
   - Security scanning stages
   - Container build process
   - Deployment automation

d) HANDS-ON EXERCISES
   Exercise 1: Read a Terraform plan output
   Exercise 2: Add a new entity type to Tier 1
   Exercise 3: Write a PHI detection test
   Exercise 4: Trace a request through routing

e) ASCII ARCHITECTURE DIAGRAMS
   - Data flow diagram
   - Network topology
   - CI/CD pipeline stages

4. demo/presentation_script.md

15-minute presentation outline:

MINUTES 0-2: THE PROBLEM
- Healthcare AI adoption barriers
- HIPAA violation consequences
- Cloud AI privacy limitations

MINUTES 2-5: OUR SOLUTION
- Zero-trust architecture overview
- 3-tier routing concept
- Dual-plane model explanation

MINUTES 5-8: LIVE DEMO
- PHI detection demonstration
- Tier 1 routing to local
- Anonymization for Tier 2
- Backend health dashboard

MINUTES 8-11: TECHNICAL DETAILS
- Infrastructure components
- Presidio integration
- Tailscale networking
- Hardware selection rationale

MINUTES 11-13: SECURITY VALIDATION
- Security scanning results
- Audit logging demonstration
- Compliance mapping

MINUTES 13-15: CONCLUSION
- Future roadmap
- Scaling considerations
- Q&A

5. demo/architecture_diagrams.txt

ASCII diagrams for presentations:

DATA FLOW DIAGRAM:
Show user query flowing through orchestrator to appropriate backend

NETWORK TOPOLOGY:
Show all machines connected via Tailscale

3-TIER ROUTING:
Show decision tree for routing

STYLE REQUIREMENTS:
- No emojis anywhere
- Professional technical writing
- Clear section headers
- Code examples with comments
- ASCII diagrams only, no external images

Create all files now.
```

---

## PROMPT 4: INFRASTRUCTURE VERIFICATION

Use this prompt to verify and test the complete infrastructure:

```
Verify the complete infrastructure setup and create test scripts.

1. CREATE scripts/verify-infrastructure.sh

A comprehensive verification script that:

a) TAILSCALE CONNECTIVITY
   - Check if tailscale is running
   - Ping each machine (kali-nexus, phantom, aegis, ryzen-ai)
   - Report reachable/unreachable status

b) SSH ACCESS
   - Test SSH to each machine with timeout
   - Report success/failure for each
   - Check for existing authorized_keys

c) SERVICE HEALTH
   - Check Aegis llama-server (http://aegis:8080/health)
   - Check Ryzen-AI Ollama (http://ryzen-ai:11434/api/tags)
   - Check Kali-Nexus security API (http://kali-nexus:8080/health)
   - Report response times

d) INFERENCE TEST
   - Send test query to orchestrator
   - Verify routing decision
   - Check response content

e) GENERATE REPORT
   - Summary of all checks
   - List of issues found
   - Recommended fixes

2. CREATE scripts/test-routing.sh

Test the 3-tier routing with sample inputs:

a) TIER 1 TESTS (must route LOCAL)
   - Send PHI query, verify LOCAL routing
   - Send SSN query, verify LOCAL routing
   - Send medical context query, verify LOCAL routing

b) TIER 2 TESTS (must anonymize)
   - Send IP address query
   - Verify anonymization in payload
   - Check routing decision

c) TIER 3 TESTS (can route anywhere)
   - Send general question
   - Verify CLOUD or LOCAL routing
   - Check response

d) ERROR HANDLING TESTS
   - Simulate Presidio failure
   - Verify fail-closed behavior
   - Check logs for raw PHI (should be none)

3. CREATE scripts/setup-all-machines.sh

Master setup script that:

a) Generates SSH keys if needed
b) Tests Tailscale connectivity
c) Provides step-by-step instructions for each machine
d) Verifies setup after completion

4. UPDATE distribute-setup.sh

Ensure it includes:
- Existing SSH key detection
- Backup of existing keys
- Tailscale status check
- Service health verification
- Clear progress indicators

Create all scripts now.
```

---

## PROMPT 5: FINAL DOCUMENTATION

Use this prompt to ensure all documentation is complete and professional:

```
Review and finalize all documentation for professional presentation.

1. UPDATE README.md

Ensure it includes:

a) PROJECT OVERVIEW
   - Clear problem statement
   - Solution summary
   - Key features

b) TEAM
   - Shifty: Infrastructure, orchestration
   - Sheniese (Shay): 3-tier routing, HIPAA compliance
   - Javier Acosta: Presidio integration, UI

c) ARCHITECTURE
   - High-level diagram (ASCII)
   - Component descriptions
   - Data flow explanation

d) QUICK START
   - Prerequisites
   - Installation steps
   - Verification commands

e) SECURITY MODEL
   - 3-tier routing explanation
   - HIPAA compliance notes
   - Audit logging

f) DOCUMENTATION LINKS
   - Setup instructions
   - API reference
   - Demo guide

2. CREATE docs/API_REFERENCE.md

Complete API documentation:

a) ORCHESTRATOR ENDPOINTS
   - GET /health
   - GET /backends
   - POST /v1/chat/completions
   - POST /analyze

b) REQUEST/RESPONSE FORMATS
   - JSON schemas
   - Example requests
   - Example responses

c) ERROR CODES
   - Standard errors
   - Routing errors
   - Backend errors

3. CREATE docs/DEPLOYMENT_GUIDE.md

Step-by-step deployment:

a) PREREQUISITES
   - Hardware requirements
   - Software requirements
   - Network requirements

b) MACHINE SETUP
   - Nexus (orchestrator)
   - Aegis (llama.cpp)
   - Ryzen-AI (Ollama)
   - Kali-Nexus (security)

c) CONFIGURATION
   - Tailscale setup
   - SSH keys
   - Firewall rules

d) VERIFICATION
   - Health checks
   - Test queries
   - Troubleshooting

4. CREATE CHANGELOG.md

Version history:

v0.1.0 - Initial infrastructure
v0.2.0 - PII detection (Javier)
v0.3.0 - Security hardening (Shay)
v1.0.0 - Production ready

5. REVIEW ALL FILES

Check every markdown file for:
- No emojis
- Professional tone
- Clear structure
- Accurate information
- Working code examples

Create and update all documentation now.
```

---

## CHECKPOINT VERIFICATION

After completing all prompts, verify:

1. GITHUB REPOSITORY
   - [ ] 17 commits with correct authors
   - [ ] Feature branches exist
   - [ ] Releases tagged
   - [ ] PR documentation in pr/ directory

2. SECURITY
   - [ ] All Tier 1 inputs route to LOCAL
   - [ ] Fail-closed error handling works
   - [ ] No raw PHI in logs
   - [ ] All HIPAA identifiers covered

3. DEMO
   - [ ] Streamlit app runs
   - [ ] Sample data loads
   - [ ] Routing visualization works
   - [ ] Student tutorial complete

4. DOCUMENTATION
   - [ ] README is professional
   - [ ] API reference complete
   - [ ] Deployment guide works
   - [ ] No emojis anywhere

5. INFRASTRUCTURE
   - [ ] All machines reachable
   - [ ] SSH keys distributed
   - [ ] Services running
   - [ ] Routing tests pass

---

## TROUBLESHOOTING

If Claude Code Desktop encounters issues:

GIT AUTHENTICATION
```
git config --global credential.helper store
# Then authenticate once manually
```

SSH KEY ISSUES
```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

PRESIDIO INSTALLATION
```
pip install presidio-analyzer presidio-anonymizer
python -m spacy download en_core_web_lg
```

SERVICE NOT RESPONDING
```
# Check if service is running
curl -v http://aegis:8080/health
curl -v http://ryzen-ai:11434/api/tags
```

---

End of prompts document.
