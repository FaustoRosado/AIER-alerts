# DEMO DAY QUICK REFERENCE

**1-Page Checklist for Demo Presentation**

---

## PRE-DEMO SETUP (1 Hour Before)

### Terminal Setup
```bash
# Terminal 1: Backend
cd backend
export AWS_REGION=us-east-1
export DYNAMODB_TABLE_NAME=aier-patient-data
uvicorn app.main:app --reload --port 8000

# Terminal 2: Frontend
cd frontend
npm run dev

# Terminal 3: Keep open for commands
cd data_viz
```

### Browser Tabs (Open in order)
1. Frontend: http://localhost:5173
2. API Docs: http://localhost:8000/docs
3. AWS S3: https://s3.console.aws.amazon.com/s3/buckets?region=us-east-1
4. AWS DynamoDB: https://console.aws.amazon.com/dynamodb/home?region=us-east-1
5. AWS Lambda: https://console.aws.amazon.com/lambda/home?region=us-east-1
6. CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups

### Verification Checks
- [ ] Backend health: http://localhost:8000/health (should return "healthy")
- [ ] Frontend loads without errors
- [ ] AWS Console accessible
- [ ] DynamoDB has data: `aws dynamodb scan --table-name aier-patient-data --limit 1`
- [ ] All terminals visible
- [ ] Presentation slides open
- [ ] Backup screenshots ready

---

## DEMO SCRIPT (30 Minutes)

### Part 1: Introduction (3 min)
**Say:**
- "We built AIER: AI-Based ER Alert System"
- "Solves problem of ER staff overwhelmed with patient data"
- "Real-time monitoring with risk assessment and alerts"

**Show:** Title slide with team names and project overview

### Part 2: Architecture Overview (5 min)
**Show:** Architecture diagram

**Explain each layer:**
1. **Data Layer:** "Kaggle diabetes dataset, 768 patient records"
2. **Storage:** "S3 for files, DynamoDB for structured data"
3. **Processing:** "Lambda processes data automatically when uploaded"
4. **API:** "FastAPI serves data with RESTful endpoints"
5. **Frontend:** "Vue.js + TypeScript + D3.js visualizations"
6. **Distribution:** "CloudFront CDN for global fast access"

**Key Points:**
- "Everything Infrastructure as Code with Terraform"
- "Serverless architecture - auto-scaling, pay-per-use"
- "Security-first: encryption, IAM, audit logs"
- "Works offline with local LLM for remote locations"

### Part 3: AWS Console Tour (4 min)

**Navigate through AWS Console:**

**S3 Bucket:**
```
Show: s3.console.aws.amazon.com
Point out:
- Data bucket with processed files
- Frontend bucket with website files
- Encryption enabled
- Versioning enabled
```

**DynamoDB Table:**
```
Show: dynamodb console
Point out:
- Table name: aier-patient-data
- Item count: 768 records
- Primary key: patient_id + timestamp
- Global Secondary Indexes for fast queries
Click "Explore items" - show sample records
```

**Lambda Function:**
```
Show: lambda console
Point out:
- Function name: aier-data-processor
- Runtime: Python 3.9
- Trigger: S3 upload event
- Recent executions
Click "Monitor" tab - show invocations graph
```

### Part 4: Live Application Demo (10 min)

**Frontend Walkthrough:**

**Step 1: Dashboard Overview**
```
Show: http://localhost:5173
Point out:
- Patient count statistics
- Risk level distribution
- Recent patient list
```

**Step 2: Data Visualizations**
```
Show D3.js charts:
- Scatter plot: BMI vs Glucose
- Bar chart: Risk level distribution
- Point out interactive features
- Hover to see tooltips
- Color coding by risk level
```

**Step 3: Filtering**
```
Demonstrate:
- Filter by risk level (show HIGH risk patients)
- Filter by age group
- Show count updates in real-time
```

**Step 4: Patient Details**
```
Click on a HIGH or CRITICAL patient
Show:
- Full patient details
- Risk score breakdown
- Medical measurements
- Alert status
```

### Part 5: API Documentation (3 min)

**Show API Docs:**
```
Navigate to: http://localhost:8000/docs
Point out:
- Swagger UI (auto-generated)
- All endpoints listed
- Try-it-out functionality
```

**Live API Test:**
```
Click on GET /api/patients
Click "Try it out"
Set parameters:
  limit: 10
  risk_level: CRITICAL
Click "Execute"
Show JSON response
```

### Part 6: Code Walkthrough (3 min)

**Show key code snippets:**

**Terraform (Infrastructure as Code):**
```hcl
# Show: terraform/main.tf
Highlight:
- S3 bucket definition
- DynamoDB table with GSI
- Lambda function configuration
Explain: "15+ resources defined, deployed with one command"
```

**FastAPI Backend:**
```python
# Show: backend/app/main.py
Highlight:
- @app.get("/api/patients") endpoint
- DynamoDB query logic
- Type hints and documentation
```

**Vue.js + TypeScript Frontend:**
```typescript
# Show: frontend/src/types/patient.ts
Highlight:
- Interface definitions
- Type safety benefits
Explain: "Catches errors before runtime"
```

### Part 7: IAM & Security (2 min)

**Explain security measures:**
- "5 team IAM users created with least-privilege access"
- "Each team member has own credentials"
- "All data encrypted at rest and in transit"
- "CloudTrail logs all actions for audit"
- "No credentials in code (Infrastructure as Code)"

**Show:** IAM users in AWS Console (briefly)

---

## PROJECT OBJECTIVES RECAP

### Sprint Achievement
- ✅ Sprint 1-2: Foundation & Planning
- ✅ Sprint 3-4: Infrastructure & Backend
- ✅ Sprint 5-6: Frontend & Integration
- 🔄 Sprint 6: Final polish & documentation

### Technical Goals Met
- ✅ Cloud-native architecture (AWS)
- ✅ Infrastructure as Code (Terraform)
- ✅ Modern web development (TypeScript, Vue.js)
- ✅ Data visualization (D3.js)
- ✅ Serverless computing (Lambda)
- ✅ NoSQL database (DynamoDB)
- ✅ CDN deployment (CloudFront)
- ✅ API design (RESTful, FastAPI)
- ✅ Security best practices (IAM, encryption)

### Business Goals Met
- ✅ Real-world problem (ER patient monitoring)
- ✅ Market validation ($100-300B impact)
- ✅ Scalable architecture
- ✅ Cost-effective solution ($5-15/month dev)
- ✅ HIPAA-aligned practices
- ✅ Team collaboration (5 members, IAM users)
- ✅ Documentation (2000+ lines)

### Replicability
- ✅ Complete documentation
- ✅ Automated deployment scripts
- ✅ Infrastructure as Code (reproducible)
- ✅ Step-by-step guides
- ✅ Git version control
- ✅ Team credential management

---

## TECH STACK POWER DEMO

### Each Component Standalone

**1. Terraform (Infrastructure as Code)**
```bash
# Show power of IaC:
terraform plan   # Preview
terraform apply  # Deploy 15+ resources
terraform destroy # Clean up

# Explain: "Same code = same infrastructure, every time"
```

**2. FastAPI (Backend)**
```
Show: http://localhost:8000/docs
Explain:
- "Auto-generated API documentation"
- "Type checking with Python hints"
- "High performance (comparable to Node.js)"
- "Easy testing with built-in client"
```

**3. Vue.js (Frontend Framework)**
```javascript
Explain:
- "Reactive data binding"
- "Component-based architecture"
- "Virtual DOM for performance"
- "Easy to learn and maintain"
```

**4. TypeScript (Type Safety)**
```typescript
interface Patient {
  patient_id: string;
  risk_level: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
}

Explain:
- "Catches errors at compile time"
- "Better IDE support"
- "Self-documenting code"
- "Easier refactoring"
```

**5. D3.js (Visualizations)**
```
Show: Interactive charts
Explain:
- "Data-driven documents"
- "Smooth animations"
- "Highly customizable"
- "Industry standard for data viz"
```

**6. AWS (Cloud Infrastructure)**
```
Show: AWS Console
Explain value of each service:
- S3: Unlimited storage, $0.023/GB/month
- DynamoDB: <10ms latency, auto-scaling
- Lambda: No servers, pay per execution
- CloudFront: Global CDN, 400+ edge locations
```

### Integration Power
**Alone:** Each tool is powerful  
**Together:** Unstoppable

- Terraform provisions infrastructure
- Lambda processes data automatically
- DynamoDB stores with fast queries
- FastAPI serves with type safety
- Vue.js renders reactively
- D3.js visualizes beautifully
- CloudFront distributes globally
- All monitored by CloudWatch

---

## AIER OFFLINE MODE

### Offline LLM Capability

**Why Needed:**
- Rural clinics without reliable internet
- Disaster response (hurricanes, earthquakes)
- Military field hospitals
- Privacy-sensitive scenarios
- Network outages

**How It Works:**
```
Local Device (Laptop/Tablet)
  ↓
Local LLM Model (e.g., Llama, GPT-J)
  ↓
Risk Assessment Algorithm
  ↓
Local Storage (SQLite)
  ↓
Local Web Interface (HTML/JS)
  ↓
Medical Staff Access

No internet required!
```

**Sync When Online:**
```
When internet available:
  → Upload local data to cloud
  → Download updated models
  → Sync patient records
  → Backup to S3
```

---

## Q&A PREPARATION

### Expected Questions & Answers

**Q: Can it scale to handle a large hospital?**
A: "Yes, serverless architecture auto-scales. DynamoDB handles millions of requests/second, Lambda scales to 1000 concurrent executions, CloudFront handles global traffic."

**Q: What about HIPAA compliance?**
A: "We follow HIPAA best practices: encryption everywhere, access controls with IAM, audit logs with CloudTrail, data anonymization. Full compliance requires BAA with AWS and additional measures."

**Q: How much does it cost in production?**
A: "Development is $5-15/month. Production depends on usage but starts around $50-100/month for small hospital. Scales linearly with usage."

**Q: Why TypeScript over JavaScript?**
A: "Type safety catches bugs before runtime, better tooling, easier maintenance. Industry standard for large projects."

**Q: Can it integrate with existing EHR systems?**
A: "Yes, designed with API-first approach. Can integrate with any system supporting HL7 FHIR standards. Would need adapters for legacy systems."

**Q: What happens if AWS goes down?**
A: "We have offline mode with local LLM. For cloud: multi-region deployment, automated backups to different regions, failover systems."

**Q: How do you ensure data privacy?**
A: "No PII, anonymized patient IDs, encryption at rest and in transit, private networks, access controls, audit trails."

**Q: What would you add next?**
A: "Real-time updates with WebSockets, user authentication with Cognito, mobile app, predictive ML models, EHR integration, automated testing, CI/CD pipeline."

**Q: How long did this take?**
A: "12 weeks following agile sprints. Could be replicated in 4-6 weeks with our documentation."

**Q: Can I see the code?**
A: "Yes, repository available at [GitHub URL]. Complete documentation, setup guides, and examples included."

---

## EMERGENCY BACKUP PLAN

If something breaks during demo:

**Backend Won't Start:**
→ Show API documentation screenshots
→ Use pre-recorded API calls
→ Show Postman collection

**Frontend Won't Load:**
→ Show screenshots of working app
→ Show pre-recorded video demo
→ Have static HTML backup

**AWS Console Issues:**
→ Show screenshots of resources
→ Use AWS CLI to show resources:
  ```bash
  aws s3 ls
  aws dynamodb list-tables
  aws lambda list-functions
  ```

**Internet Connection Lost:**
→ "This is where offline mode comes in!"
→ Show offline architecture diagram
→ Explain offline capabilities

**Code Editor Won't Open:**
→ Have code printed in slides
→ Show GitHub repository online

**Complete System Failure:**
→ Show pre-recorded video demo (5 min)
→ Walk through slides with screenshots
→ Focus on architecture and learnings

---

## DEMO TIMING

**Total: 30 minutes**

- 0-3 min: Introduction
- 3-8 min: Architecture & tech stack
- 8-12 min: AWS Console tour
- 12-22 min: Live application demo
- 22-25 min: API documentation
- 25-28 min: Code walkthrough
- 28-30 min: Wrap-up & Q&A start

**Flexibility:** If running short, expand code walkthrough. If running long, shorten AWS Console tour.

---

## POST-DEMO CLEANUP

**Immediately After Demo:**
```bash
# Don't destroy yet! Let evaluators explore.
# Just take notes of feedback.
```

**After Evaluation Complete:**
```bash
# Destroy infrastructure to avoid charges
cd terraform
terraform destroy

# Verify everything deleted
bash scripts/04_verify_deployment.sh

# Should show: No resources found
```

**Documentation Handoff:**
- Export CloudWatch logs
- Take screenshots of metrics
- Export DynamoDB data sample
- Document lessons learned
- Update README with final notes

---

## SUCCESS INDICATORS

**Demo Successful If:**
- ✅ All components shown working
- ✅ Architecture clearly explained
- ✅ Questions answered confidently
- ✅ Technical depth demonstrated
- ✅ Business value articulated
- ✅ Team collaboration evident
- ✅ Replicability proven

**Bonus Points:**
- 🌟 Live coding small feature
- 🌟 Show cost optimization
- 🌟 Demonstrate disaster recovery
- 🌟 Show security testing
- 🌟 Present future roadmap

---

## FINAL PRE-DEMO CHECKLIST

**5 Minutes Before:**
- [ ] All browser tabs open and logged in
- [ ] Both servers running (backend & frontend)
- [ ] Demo script in front of you
- [ ] Water nearby
- [ ] Phone on silent
- [ ] Screen sharing tested (if virtual)
- [ ] Backup plan ready
- [ ] Team ready
- [ ] Positive attitude 😊

**Remember:**
- Breathe
- Speak slowly and clearly
- Make eye contact
- Smile
- You've built something amazing!
- You know this material
- You've got this! 🚀

---

**Good luck team! Let's show them what we've built!**

