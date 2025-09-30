"""
AIER Alert System - FastAPI Backend
Main application entry point
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
import boto3
from boto3.dynamodb.conditions import Key
import os
from datetime import datetime

# Initialize FastAPI app
app = FastAPI(
    title="AIER Alert System API",
    description="API for patient monitoring and visualization",
    version="1.0.0"
)

# CORS Configuration - Allow frontend to access API
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",  # Vue.js dev server
        "http://localhost:3000",   # Alternative port
        "*"  # Allow all in development - restrict in production
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# AWS Configuration
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE_NAME", "aier-patient-data")

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
table = dynamodb.Table(DYNAMODB_TABLE)

@app.get("/")
async def root():
    """
    Root endpoint - API information
    """
    return {
        "service": "AIER Alert System API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "patients": "/api/patients",
            "patient_detail": "/api/patients/{patient_id}",
            "statistics": "/api/statistics",
            "visualization_data": "/api/visualizations/{chart_type}"
        },
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring
    """
    try:
        # Test DynamoDB connection
        response = table.scan(Limit=1)
        
        return {
            "status": "healthy",
            "service": "api",
            "dynamodb": "connected",
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Service unhealthy: {str(e)}"
        )

@app.get("/api/patients")
async def get_patients(
    limit: int = Query(50, ge=1, le=100),
    risk_level: Optional[str] = None
):
    """
    Get list of patients with optional filtering
    
    Parameters:
    - limit: Number of records to return (1-100)
    - risk_level: Filter by risk level (LOW, MEDIUM, HIGH, CRITICAL)
    """
    try:
        if risk_level:
            # Query using Global Secondary Index
            response = table.query(
                IndexName='RiskLevelIndex',
                KeyConditionExpression=Key('risk_level').eq(risk_level.upper()),
                Limit=limit
            )
        else:
            # Scan all records
            response = table.scan(Limit=limit)
        
        patients = response.get('Items', [])
        
        return {
            "status": "success",
            "data": {
                "patients": patients,
                "count": len(patients),
                "has_more": 'LastEvaluatedKey' in response
            },
            "metadata": {
                "timestamp": datetime.utcnow().isoformat(),
                "filters": {"risk_level": risk_level} if risk_level else {}
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch patients: {str(e)}"
        )

@app.get("/api/patients/{patient_id}")
async def get_patient(patient_id: str):
    """
    Get detailed information for a specific patient
    
    Parameters:
    - patient_id: Patient identifier (e.g., PT-00001)
    """
    try:
        response = table.query(
            KeyConditionExpression=Key('patient_id').eq(patient_id),
            ScanIndexForward=False,  # Most recent first
            Limit=1
        )
        
        items = response.get('Items', [])
        if not items:
            raise HTTPException(
                status_code=404,
                detail=f"Patient {patient_id} not found"
            )
        
        return {
            "status": "success",
            "data": items[0],
            "metadata": {
                "timestamp": datetime.utcnow().isoformat()
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch patient: {str(e)}"
        )

@app.get("/api/statistics")
async def get_statistics():
    """
    Get overall dataset statistics and aggregations
    """
    try:
        # Scan all records for statistics
        # In production, cache this or use pre-computed aggregates
        response = table.scan()
        patients = response.get('Items', [])
        
        # Calculate statistics
        total_patients = len(patients)
        
        # Risk level distribution
        risk_distribution = {}
        for patient in patients:
            risk = patient.get('risk_level', 'UNKNOWN')
            risk_distribution[risk] = risk_distribution.get(risk, 0) + 1
        
        # Age group distribution
        age_distribution = {}
        for patient in patients:
            age_group = patient.get('age_group', 'Unknown')
            age_distribution[age_group] = age_distribution.get(age_group, 0) + 1
        
        # Diabetes prevalence
        diabetes_count = sum(1 for p in patients if p.get('Outcome') == 1)
        diabetes_prevalence = diabetes_count / total_patients if total_patients > 0 else 0
        
        # Average metrics
        avg_glucose = sum(float(p.get('Glucose', 0)) for p in patients) / total_patients if total_patients > 0 else 0
        avg_bmi = sum(float(p.get('BMI', 0)) for p in patients) / total_patients if total_patients > 0 else 0
        avg_age = sum(float(p.get('Age', 0)) for p in patients) / total_patients if total_patients > 0 else 0
        
        return {
            "status": "success",
            "data": {
                "total_patients": total_patients,
                "diabetes_prevalence": round(diabetes_prevalence, 3),
                "risk_distribution": risk_distribution,
                "age_distribution": age_distribution,
                "averages": {
                    "glucose": round(avg_glucose, 1),
                    "bmi": round(avg_bmi, 1),
                    "age": round(avg_age, 1)
                }
            },
            "metadata": {
                "timestamp": datetime.utcnow().isoformat()
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to calculate statistics: {str(e)}"
        )

@app.get("/api/visualizations/scatter")
async def get_scatter_data():
    """
    Get data formatted for scatter plot visualization
    Returns: BMI vs Glucose with risk level coloring
    """
    try:
        response = table.scan(Limit=500)
        patients = response.get('Items', [])
        
        scatter_data = []
        for patient in patients:
            scatter_data.append({
                "patient_id": patient.get('patient_id'),
                "bmi": float(patient.get('BMI', 0)),
                "glucose": float(patient.get('Glucose', 0)),
                "age": int(patient.get('Age', 0)),
                "risk_level": patient.get('risk_level', 'UNKNOWN'),
                "outcome": int(patient.get('Outcome', 0))
            })
        
        return {
            "status": "success",
            "data": scatter_data,
            "metadata": {
                "chart_type": "scatter",
                "x_axis": "BMI",
                "y_axis": "Glucose",
                "color": "risk_level",
                "timestamp": datetime.utcnow().isoformat()
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate scatter data: {str(e)}"
        )

@app.get("/api/visualizations/distribution")
async def get_distribution_data():
    """
    Get data for distribution charts (histograms, bar charts)
    """
    try:
        response = table.scan()
        patients = response.get('Items', [])
        
        # Age distribution
        age_ranges = {
            '<30': 0, '30-40': 0, '40-50': 0, '50-60': 0, '60+': 0
        }
        
        for patient in patients:
            age = int(patient.get('Age', 0))
            if age < 30:
                age_ranges['<30'] += 1
            elif age < 40:
                age_ranges['30-40'] += 1
            elif age < 50:
                age_ranges['40-50'] += 1
            elif age < 60:
                age_ranges['50-60'] += 1
            else:
                age_ranges['60+'] += 1
        
        # Risk level distribution
        risk_dist = {}
        for patient in patients:
            risk = patient.get('risk_level', 'UNKNOWN')
            risk_dist[risk] = risk_dist.get(risk, 0) + 1
        
        return {
            "status": "success",
            "data": {
                "age_distribution": age_ranges,
                "risk_distribution": risk_dist
            },
            "metadata": {
                "chart_type": "distribution",
                "timestamp": datetime.utcnow().isoformat()
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate distribution data: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
