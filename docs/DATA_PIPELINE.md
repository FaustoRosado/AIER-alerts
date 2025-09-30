# AIER Data Pipeline Documentation

## Overview

This document explains the data pipeline architecture for the AIER Alert System Frontend Visualization. The pipeline processes the Kaggle Diabetes Dataset through AWS services to provide real-time visualizations.

## Pipeline Architecture

```
Kaggle Dataset (diabetes.csv)
        |
        v
    [Local Processing]
        |
        v
    AWS S3 Bucket (Raw Data)
        |
        v
    AWS Lambda (Data Processing)
        |
        v
    AWS DynamoDB (Processed Data)
        |
        v
    API Gateway + FastAPI
        |
        v
    Vue.js Frontend (D3.js Visualizations)
        |
        v
    CloudFront CDN (Global Delivery)
```

## Data Flow Stages

### Stage 1: Data Acquisition

**Source**: Kaggle Diabetes Dataset
**URL**: https://www.kaggle.com/datasets/hasibur013/diabetes-dataset

**Dataset Features**:
- Pregnancies: Number of times pregnant
- Glucose: Plasma glucose concentration
- BloodPressure: Diastolic blood pressure (mm Hg)
- SkinThickness: Triceps skin fold thickness (mm)
- Insulin: 2-Hour serum insulin (mu U/ml)
- BMI: Body mass index (weight in kg/(height in m)^2)
- DiabetesPedigreeFunction: Diabetes pedigree function
- Age: Age in years
- Outcome: Class variable (0 or 1) indicating diabetes presence

**Download Process**:

```bash
# Using Kaggle API
python scripts/download-dataset.py
```

This script:
1. Authenticates with Kaggle API
2. Downloads the diabetes dataset
3. Validates file integrity
4. Saves to `data/diabetes.csv`

### Stage 2: Local Data Processing

**Script**: `scripts/data-pipeline.py`

**Processing Steps**:

1. **Data Validation**
   - Check for missing values
   - Validate data types
   - Ensure all required columns present
   - Verify data ranges

2. **Data Cleaning**
   - Handle zero values (medical impossibilities)
   - Remove outliers beyond clinical thresholds
   - Normalize data formats

3. **Anonymization**
   - Generate random patient IDs
   - Remove any identifying information
   - Add timestamp for data versioning

4. **Feature Engineering**
   - Calculate risk scores
   - Create age groups
   - Generate BMI categories
   - Compute diabetes risk levels

**Output**: Processed CSV file ready for cloud upload

### Stage 3: S3 Storage

**Bucket Structure**:

```
aier-data-[environment]/
├── raw/
│   └── diabetes_[timestamp].csv          # Original data
├── processed/
│   └── diabetes_processed_[timestamp].csv # Cleaned data
└── archived/
    └── [older versions]                   # Historical data
```

**Upload Process**:

```python
# Automated via data-pipeline.py
aws s3 cp data/diabetes_processed.csv s3://aier-data-prod/processed/
```

**S3 Configuration**:
- Encryption: AES-256 (server-side)
- Versioning: Enabled
- Lifecycle: Archive to Glacier after 90 days
- Access: Private with IAM role-based access

### Stage 4: Lambda Processing

**Function**: `aier-data-processor`

**Trigger**: S3 PUT event on processed/ prefix

**Processing Logic**:

1. **Read from S3**
   - Fetch newly uploaded CSV
   - Parse into memory-efficient chunks

2. **Transform Data**
   - Convert CSV rows to DynamoDB items
   - Generate partition and sort keys
   - Add metadata (ingestion time, version)

3. **Calculate Metrics**
   - Patient risk scores
   - Population statistics
   - Trend indicators

4. **Write to DynamoDB**
   - Batch write operations
   - Error handling and retry logic
   - Update metadata table

**Runtime**: Python 3.9
**Memory**: 512 MB
**Timeout**: 5 minutes
**Concurrency**: 10

**Environment Variables**:
```
DYNAMODB_TABLE_NAME=aier-patient-data
S3_BUCKET_NAME=aier-data-prod
LOG_LEVEL=INFO
```

### Stage 5: DynamoDB Storage

**Table Design**:

**Table Name**: `aier-patient-data`

**Primary Key**:
- Partition Key: `patient_id` (String)
- Sort Key: `timestamp` (Number)

**Attributes**:
```
{
  "patient_id": "PT-00001",
  "timestamp": 1640995200,
  "pregnancies": 6,
  "glucose": 148,
  "blood_pressure": 72,
  "skin_thickness": 35,
  "insulin": 0,
  "bmi": 33.6,
  "diabetes_pedigree": 0.627,
  "age": 50,
  "outcome": 1,
  "risk_score": 0.75,
  "risk_level": "HIGH",
  "age_group": "40-60",
  "bmi_category": "Obese"
}
```

**Indexes**:

Global Secondary Index 1:
- Partition Key: `risk_level`
- Sort Key: `risk_score`
- Purpose: Query patients by risk level

Global Secondary Index 2:
- Partition Key: `age_group`
- Sort Key: `glucose`
- Purpose: Demographic analysis

**Capacity**:
- Mode: On-demand (pay per request)
- Scales automatically with traffic
- No capacity planning required

### Stage 6: API Layer

**Technology**: FastAPI (Python)

**Endpoints**:

```
GET /api/patients
- List all patients with pagination
- Query parameters: limit, offset, risk_level

GET /api/patients/{patient_id}
- Get specific patient details
- Includes full medical profile

GET /api/statistics
- Overall dataset statistics
- Risk distribution
- Demographic breakdown

GET /api/visualizations/scatter
- Scatter plot data (glucose vs BMI)
- Returns JSON for D3.js rendering

GET /api/visualizations/distribution
- Risk level distribution
- Age group analysis

GET /api/visualizations/trends
- Time-series trends
- Population health metrics

POST /api/alerts/simulate
- Simulate patient data input
- Test alert generation
- Demo purposes only
```

**Response Format**:

```json
{
  "status": "success",
  "data": {
    "patients": [...],
    "total_count": 768,
    "page": 1,
    "per_page": 50
  },
  "metadata": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0.0"
  }
}
```

**Error Handling**:

```json
{
  "status": "error",
  "error": {
    "code": "PATIENT_NOT_FOUND",
    "message": "Patient ID does not exist",
    "details": "No record found for PT-99999"
  }
}
```

**Authentication**: JWT tokens (for production deployment)

**Rate Limiting**: 100 requests per minute per IP

### Stage 7: Frontend Visualization

**Technology Stack**:
- TypeScript
- Vue.js 3
- D3.js
- Axios

**Visualization Components**:

1. **Dashboard Overview**
   - Total patient count
   - Risk level distribution (pie chart)
   - Average metrics (cards)

2. **Scatter Plot**
   - X-axis: BMI
   - Y-axis: Glucose levels
   - Color: Risk level
   - Size: Age
   - Interactive tooltips

3. **Bar Chart**
   - Age group distribution
   - Risk levels per group
   - Filterable by outcome

4. **Heat Map**
   - Correlation matrix
   - All medical features
   - Color scale: -1 to +1

5. **Time Series** (if temporal data available)
   - Trend lines
   - Moving averages
   - Prediction intervals

**Data Refresh**:
- Automatic refresh every 30 seconds
- Manual refresh button
- Real-time updates via WebSocket (future enhancement)

### Stage 8: CloudFront CDN

**Distribution Configuration**:

**Origin**: S3 bucket with static frontend files

**Cache Behavior**:
- HTML: No caching (always fresh)
- CSS/JS: Cache for 1 day
- Images: Cache for 7 days
- API calls: Pass through to origin

**Security**:
- HTTPS only
- Origin Access Control (OAC)
- Custom headers for security

**Performance**:
- Edge locations: Global
- Compression: Gzip and Brotli enabled
- HTTP/2 and HTTP/3 support

## Data Quality and Validation

### Input Validation

**CSV Validation**:
```python
def validate_csv(df):
    required_columns = [
        'Pregnancies', 'Glucose', 'BloodPressure',
        'SkinThickness', 'Insulin', 'BMI',
        'DiabetesPedigreeFunction', 'Age', 'Outcome'
    ]
    
    # Check columns exist
    if not all(col in df.columns for col in required_columns):
        raise ValidationError("Missing required columns")
    
    # Check data types
    if not df['Glucose'].dtype in [int, float]:
        raise ValidationError("Invalid glucose data type")
    
    # Check value ranges
    if (df['Glucose'] < 0).any() or (df['Glucose'] > 300).any():
        raise ValidationError("Glucose values out of range")
    
    return True
```

### Data Cleaning Rules

**Blood Pressure**:
- Replace 0 with median (74)
- Valid range: 40-200 mmHg

**Glucose**:
- Replace 0 with median (117)
- Valid range: 40-300 mg/dL

**BMI**:
- Replace 0 with median (32)
- Valid range: 15-60

**Insulin**:
- 0 is valid (not measured)
- Valid range when measured: 15-400 mu U/ml

### Error Handling

**S3 Upload Failures**:
```python
try:
    s3_client.upload_file(file_path, bucket, key)
except ClientError as e:
    logger.error(f"S3 upload failed: {e}")
    # Retry with exponential backoff
    retry_upload(file_path, bucket, key)
```

**DynamoDB Write Failures**:
```python
try:
    table.put_item(Item=item)
except ClientError as e:
    if e.response['Error']['Code'] == 'ProvisionedThroughputExceededException':
        time.sleep(1)  # Wait and retry
        table.put_item(Item=item)
    else:
        logger.error(f"DynamoDB error: {e}")
        raise
```

## Performance Optimization

### Lambda Optimization

1. **Memory Configuration**: 512 MB for CSV processing
2. **Batch Processing**: Process 100 records at a time
3. **Connection Pooling**: Reuse DynamoDB connections
4. **Async Operations**: Use aioboto3 for parallel uploads

### DynamoDB Optimization

1. **Partition Key Design**: Even distribution across partitions
2. **Batch Operations**: Use batch_write_item
3. **Projection**: Only fetch required attributes
4. **Caching**: Implement DAX for read-heavy workloads

### API Optimization

1. **Response Caching**: Cache statistics for 5 minutes
2. **Pagination**: Limit results to 50 per page
3. **Field Selection**: Allow clients to specify fields
4. **Compression**: Gzip all responses

## Monitoring and Logging

### CloudWatch Metrics

**Lambda Metrics**:
- Invocations
- Duration
- Errors
- Throttles

**DynamoDB Metrics**:
- Read/Write Capacity
- Throttled Requests
- System Errors

**API Gateway Metrics**:
- Request Count
- Latency
- 4XX/5XX Errors

### Custom Metrics

```python
# Log processing metrics
cloudwatch.put_metric_data(
    Namespace='AIER/DataPipeline',
    MetricData=[
        {
            'MetricName': 'RecordsProcessed',
            'Value': record_count,
            'Unit': 'Count'
        },
        {
            'MetricName': 'ProcessingDuration',
            'Value': duration_ms,
            'Unit': 'Milliseconds'
        }
    ]
)
```

### Logging Strategy

**Log Levels**:
- ERROR: Processing failures, data corruption
- WARN: Data quality issues, validation warnings
- INFO: Pipeline progress, record counts
- DEBUG: Detailed processing steps (dev only)

**Log Format**:
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "component": "data-processor",
  "message": "Processed 768 records",
  "metadata": {
    "records_processed": 768,
    "duration_ms": 1250,
    "source_file": "diabetes_20240115.csv"
  }
}
```

## Security Considerations

### Data Encryption

**At Rest**:
- S3: AES-256 encryption
- DynamoDB: AWS KMS encryption
- Backups: Encrypted snapshots

**In Transit**:
- HTTPS only for all API calls
- TLS 1.2+ required
- Certificate pinning (mobile apps)

### Access Control

**IAM Policies**:
- Least privilege principle
- Separate roles for Lambda, API, developers
- MFA required for production access

**Data Anonymization**:
- No real patient names
- Generated patient IDs
- No personally identifiable information (PII)

### Compliance

**HIPAA Considerations**:
- Audit logging enabled
- Encryption enforced
- Access controls documented
- Regular security assessments

Note: This demo uses synthetic/anonymized data. Real PHI requires additional safeguards.

## Troubleshooting

### Common Issues

**Issue**: Lambda timeout during large file processing

**Solution**:
- Increase timeout to 15 minutes
- Process in smaller batches
- Use Step Functions for orchestration

**Issue**: DynamoDB throttling errors

**Solution**:
- Switch to on-demand capacity mode
- Implement exponential backoff
- Optimize batch operations

**Issue**: S3 upload failures

**Solution**:
- Check IAM permissions
- Verify bucket policy
- Enable S3 Transfer Acceleration

### Pipeline Health Checks

```bash
# Check S3 bucket
aws s3 ls s3://aier-data-prod/processed/

# Check Lambda function
aws lambda get-function --function-name aier-data-processor

# Check DynamoDB table
aws dynamodb describe-table --table-name aier-patient-data

# View CloudWatch logs
aws logs tail /aws/lambda/aier-data-processor --follow
```

## Testing the Pipeline

### End-to-End Test

```bash
# Run complete pipeline test
python scripts/test-pipeline.py

# Expected output:
# [PASS] CSV downloaded
# [PASS] Data validated
# [PASS] S3 upload successful
# [PASS] Lambda triggered
# [PASS] DynamoDB populated
# [PASS] API responding
# [PASS] Frontend rendering
```

### Unit Tests

```bash
# Test data validation
pytest tests/test_validation.py

# Test transformations
pytest tests/test_transforms.py

# Test API endpoints
pytest tests/test_api.py
```

## Future Enhancements

1. **Real-time Streaming**: Replace batch with Kinesis Data Streams
2. **Machine Learning**: Add SageMaker for predictive models
3. **Multi-region**: Deploy to multiple AWS regions
4. **Advanced Analytics**: Integrate with Athena for SQL queries
5. **Alerting**: Add SNS notifications for anomalies

## References

- AWS Lambda Documentation: https://docs.aws.amazon.com/lambda/
- DynamoDB Best Practices: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html
- FastAPI Documentation: https://fastapi.tiangolo.com/
- D3.js Documentation: https://d3js.org/
