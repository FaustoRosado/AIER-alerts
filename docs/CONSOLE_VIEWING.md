# AWS Console Viewing Guide - No Federation Token Needed

## Direct AWS Console Access (Recommended)

Your team can watch infrastructure being created/destroyed in the AWS Console browser **without** the federation token script.

---

## Option 1: Direct Console Login (Best for Viewing)

### Access the AWS Console

**URL**: https://console.aws.amazon.com/

**Login with**:
- **Account ID**: `123456789012`
- **IAM Username**: [provided by team lead]
- **Password**: [provided by team lead]

**OR** if you have root access:
- **Email**: [root account email]
- **Password**: [root account password]

### Once Logged In

Team members can view everything in real-time as Terraform scripts run!

---

## Step-by-Step: Watch Terraform Create Resources

### Before Running Terraform

1. **Open AWS Console** in browser: https://console.aws.amazon.com/
2. **Log in** with credentials
3. **Open multiple tabs** for different services:

   **Tab 1 - S3 Buckets**:
   https://s3.console.aws.amazon.com/s3/buckets?region=us-east-1

   **Tab 2 - DynamoDB Tables**:
   https://console.aws.amazon.com/dynamodbv2/home?region=us-east-1#tables

   **Tab 3 - Lambda Functions**:
   https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions

   **Tab 4 - CloudFront Distributions**:
   https://console.aws.amazon.com/cloudfront/v3/home

   **Tab 5 - CloudWatch Logs**:
   https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups

### Run Terraform Scripts

**Terminal Window:**
```bash
cd data_viz

# Initialize
bash scripts/01_init_terraform.sh

# Plan
bash scripts/02_plan_terraform.sh

# Apply (creates resources)
bash scripts/03_apply_terraform.sh
```

### Watch in Console (Real-Time)

As Terraform runs, **refresh each browser tab** to see resources appear:

1. **S3 Tab** - Watch buckets being created:
   - `aier-data-dev`
   - `aier-frontend-dev`

2. **DynamoDB Tab** - Watch table appear:
   - `aier-patient-data`

3. **Lambda Tab** - Watch function appear:
   - `aier-data-processor`

4. **CloudFront Tab** - Watch distribution deploy:
   - Status: "In Progress" → "Deployed"

5. **CloudWatch Tab** - Watch log groups appear:
   - `/aws/lambda/aier-data-processor`

---

## Detailed Viewing Checklist

### 1. S3 Buckets

**URL**: https://s3.console.aws.amazon.com/s3/buckets?region=us-east-1

**What to Look For**:
- ✅ `aier-data-dev` - Data storage bucket
- ✅ `aier-frontend-dev` - Frontend hosting bucket

**Click on bucket** to see:
- Objects/files inside
- Properties (versioning enabled)
- Permissions (public access blocked)
- Encryption settings (AES-256)

### 2. DynamoDB Tables

**URL**: https://console.aws.amazon.com/dynamodbv2/home?region=us-east-1#tables

**What to Look For**:
- ✅ `aier-patient-data` table

**Click on table** to see:
- Items (patient records after data upload)
- Indexes (RiskLevelIndex, AgeGroupIndex)
- Metrics (read/write capacity)
- Capacity mode (on-demand)

**View Items**:
1. Click table name
2. Click "Explore table items"
3. Click "Scan" to see all records

### 3. Lambda Functions

**URL**: https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions

**What to Look For**:
- ✅ `aier-data-processor` function

**Click on function** to see:
- Code (if you want to review)
- Configuration (memory: 512 MB, timeout: 300s)
- Environment variables (DynamoDB table name, S3 bucket)
- Triggers (S3 bucket event)
- Monitoring (CloudWatch metrics)

### 4. CloudFront Distributions

**URL**: https://console.aws.amazon.com/cloudfront/v3/home

**What to Look For**:
- ✅ Distribution for frontend

**Note**: Takes 10-15 minutes to deploy

**Click on distribution** to see:
- Domain name (e.g., `d1234567890.cloudfront.net`)
- Origin (S3 bucket)
- Behaviors (caching rules)
- Status (In Progress → Deployed)

### 5. IAM Roles

**URL**: https://console.aws.amazon.com/iam/home?region=us-east-1#/roles

**Search for**: `aier`

**What to Look For**:
- ✅ `aier-lambda-execution` role

**Click on role** to see:
- Trust relationships (who can assume this role)
- Permissions policies (what the role can do)

### 6. CloudWatch Logs

**URL**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups

**What to Look For**:
- ✅ `/aws/lambda/aier-data-processor`

**After data upload**, click log group to see:
- Log streams (Lambda executions)
- Processing events
- Any errors

---

## Watch Terraform Destroy Resources

### Run Destroy Script

**Terminal:**
```bash
bash scripts/99_destroy_terraform.sh
# Type 'destroy' and 'yes' to confirm
```

### Watch in Console

**Refresh browser tabs** to see resources disappear:

1. **CloudFront** - Status: "In Progress" (being deleted)
2. **Lambda** - Function disappears
3. **DynamoDB** - Table status: "Deleting" → Gone
4. **S3** - Buckets disappear (after emptying)
5. **CloudWatch** - Log groups may remain (cleanup manually if needed)

**Note**: Destruction takes 5-10 minutes (CloudFront is slowest)

---

## Side-by-Side Workflow

### Recommended Setup

**Left Screen**: Terminal running Terraform scripts
```bash
bash scripts/03_apply_terraform.sh
```

**Right Screen**: Browser with AWS Console tabs
- Refresh to see real-time changes
- Verify each resource as it's created
- Check configuration matches Terraform plan

### Example Workflow

**Step 1**: Run plan
```bash
bash scripts/02_plan_terraform.sh
```

**Step 2**: Review in terminal:
```
Plan: 15 to add, 0 to change, 0 to destroy
```

**Step 3**: Apply
```bash
bash scripts/03_apply_terraform.sh
```

**Step 4**: Watch in console (refresh periodically):
- S3 buckets appear
- DynamoDB table appears
- Lambda function appears
- CloudFront starts deploying

**Step 5**: Verify
```bash
bash scripts/04_verify_deployment.sh
```

**Step 6**: Confirm in console by clicking each resource

---

## Console Navigation Tips

### Quick Service Search

Press `/` (forward slash) in AWS Console to search:
- Type "S3" → Enter
- Type "DynamoDB" → Enter
- Type "Lambda" → Enter

### Pin Services

**Pin frequently used services**:
1. Hover over service name
2. Click "Pin" icon
3. Service appears in top bar

**Recommended pins**:
- S3
- DynamoDB
- Lambda
- CloudFront
- CloudWatch

### Region Selection

**Always check region** (top-right corner):
- Should be: **US East (N. Virginia) us-east-1**
- Some resources are global (IAM, CloudFront)
- Most are regional (S3, DynamoDB, Lambda)

---

## Alternative: AWS CLI from Console

If you're in the console but want CLI output:

**CloudShell** (built into AWS Console):
1. Click CloudShell icon (>_) in top bar
2. Wait for terminal to load
3. Run commands:
   ```bash
   aws s3 ls | grep aier
   aws dynamodb list-tables
   aws lambda list-functions
   ```

---

## Team Demo Workflow

### Perfect for Sprint Demos

**Presenter**:
1. Share screen showing terminal + browser
2. Run Terraform apply
3. Narrate what's happening
4. Refresh browser tabs showing resources appearing
5. Click into each service to show details

**Script for Demo**:
```
"Now I'm running our Terraform deployment script...
[run 03_apply_terraform.sh]

Let me show you what's being created in AWS...
[switch to S3 tab, refresh]

Here you can see our data storage bucket has been created...
[click bucket, show properties]

Now let's check DynamoDB...
[switch to DynamoDB tab, refresh]

Our patient data table is ready with the indexes we defined...
[click table, show schema]

And here's our Lambda function for data processing...
[switch to Lambda tab, show function]

Finally, CloudFront is deploying our frontend globally...
[show CloudFront distribution]
"
```

---

## Verification Checklist

After running `03_apply_terraform.sh`, verify in console:

### S3 Buckets ✅
- [ ] `aier-data-dev` exists
- [ ] Versioning enabled
- [ ] Encryption enabled
- [ ] Public access blocked

### DynamoDB ✅
- [ ] `aier-patient-data` exists
- [ ] Billing mode: On-demand
- [ ] Hash key: `patient_id`
- [ ] Range key: `timestamp`
- [ ] GSI: `RiskLevelIndex`
- [ ] GSI: `AgeGroupIndex`

### Lambda ✅
- [ ] `aier-data-processor` exists
- [ ] Runtime: Python 3.9
- [ ] Memory: 512 MB
- [ ] Timeout: 300 seconds
- [ ] Environment variables set
- [ ] S3 trigger configured

### CloudFront ✅
- [ ] Distribution created
- [ ] Status: Deployed
- [ ] Origin: S3 bucket
- [ ] HTTPS enabled

### IAM ✅
- [ ] `aier-lambda-execution` role exists
- [ ] Appropriate policies attached

### CloudWatch ✅
- [ ] Log group created
- [ ] Retention: 7 days

---

## After Data Upload

After running `python scripts/data-pipeline.py --upload`:

### Check S3
**URL**: Click into `aier-data-dev` bucket
- See: `processed/diabetes_processed_[timestamp].csv`
- See: `statistics/stats_[timestamp].json`

### Check DynamoDB
**URL**: Click "Explore table items" on `aier-patient-data`
- Click "Scan"
- Should see 700+ patient records
- Each with: patient_id, glucose, BMI, risk_level, etc.

### Check CloudWatch Logs
**URL**: Click log group `/aws/lambda/aier-data-processor`
- See: Log streams from Lambda executions
- See: "Processed X records" messages

---

## No GetFederationToken Needed!

**The key point**: Your team doesn't need the federation token script at all!

### Team Members Just:
1. **Get AWS Console credentials** from team lead
2. **Log in** to https://console.aws.amazon.com/
3. **Navigate** to services (S3, DynamoDB, Lambda, etc.)
4. **Watch** resources appear/disappear as scripts run
5. **Verify** everything is working correctly

### Benefits of Console Viewing:
- ✅ Visual confirmation of infrastructure
- ✅ Real-time monitoring during deployment
- ✅ Click-through to see detailed configuration
- ✅ Easy for demos and presentations
- ✅ Great for learning and understanding AWS
- ✅ No special permissions needed (just console login)

---

## Summary

### Question: Can team view in AWS Console?
**Answer**: **YES!** No federation token needed.

### How?
1. Log in to AWS Console with credentials
2. Navigate to service pages (S3, DynamoDB, Lambda, CloudFront)
3. Refresh pages to see resources as Terraform creates/destroys them
4. Click into resources to see details

### When?
- **During**: `bash scripts/03_apply_terraform.sh` (watch creation)
- **After**: Verify resources exist and are configured correctly
- **During**: `bash scripts/99_destroy_terraform.sh` (watch deletion)

### Why This is Better:
- More visual and intuitive
- Shows real AWS interface (what they'll use in real jobs)
- No special permissions required
- Works for demos and learning
- Perfect for team collaboration

---

**Your team can follow along perfectly in the AWS Console as CLI scripts run!** 🎯
