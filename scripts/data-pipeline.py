#!/usr/bin/env python3
"""
AIER Alert System - Data Pipeline
Processes Kaggle diabetes dataset and uploads to AWS
"""

import os
import sys
import json
import argparse
from pathlib import Path
from datetime import datetime
import pandas as pd
import boto3
from botocore.exceptions import ClientError

# Paths
BASE_DIR = Path(__file__).parent.parent
DATA_DIR = BASE_DIR / "data"
INPUT_FILE = DATA_DIR / "diabetes.csv"
OUTPUT_FILE = DATA_DIR / "diabetes_processed.csv"

# AWS Configuration
AWS_REGION = os.getenv("AWS_DEFAULT_REGION", "us-east-1")
S3_BUCKET = os.getenv("S3_BUCKET_NAME", "aier-data-dev")

class DataPipeline:
    """Process and upload diabetes dataset"""
    
    def __init__(self):
        self.df = None
        self.stats = {}
    
    def load_data(self):
        """Load diabetes dataset from CSV"""
        print("Loading dataset...")
        
        if not INPUT_FILE.exists():
            raise FileNotFoundError(
                f"Dataset not found: {INPUT_FILE}\n"
                f"Run: python scripts/download-dataset.py"
            )
        
        self.df = pd.read_csv(INPUT_FILE)
        print(f"Loaded {len(self.df)} records")
        print(f"Columns: {list(self.df.columns)}")
        return self
    
    def validate_data(self):
        """Validate dataset structure and content"""
        print("\nValidating data...")
        
        required_columns = [
            'Pregnancies', 'Glucose', 'BloodPressure',
            'SkinThickness', 'Insulin', 'BMI',
            'DiabetesPedigreeFunction', 'Age', 'Outcome'
        ]
        
        # Check columns
        missing = set(required_columns) - set(self.df.columns)
        if missing:
            raise ValueError(f"Missing columns: {missing}")
        
        # Check for nulls
        null_counts = self.df[required_columns].isnull().sum()
        if null_counts.any():
            print(f"WARNING: Found null values:\n{null_counts[null_counts > 0]}")
        
        # Check value ranges
        issues = []
        if (self.df['Glucose'] > 300).any():
            issues.append("Glucose > 300")
        if (self.df['BloodPressure'] > 200).any():
            issues.append("BloodPressure > 200")
        if (self.df['BMI'] > 60).any():
            issues.append("BMI > 60")
        
        if issues:
            print(f"WARNING: Found outliers: {', '.join(issues)}")
        
        print("Validation complete")
        return self
    
    def clean_data(self):
        """Clean and transform dataset"""
        print("\nCleaning data...")
        
        # Replace zero values with median (medical impossibility)
        zero_cols = ['Glucose', 'BloodPressure', 'BMI']
        for col in zero_cols:
            if col in self.df.columns:
                median = self.df[self.df[col] != 0][col].median()
                zero_count = (self.df[col] == 0).sum()
                if zero_count > 0:
                    print(f"Replacing {zero_count} zero values in {col} with median {median}")
                    self.df.loc[self.df[col] == 0, col] = median
        
        # Remove extreme outliers
        outlier_threshold = {
            'Glucose': (40, 300),
            'BloodPressure': (40, 200),
            'BMI': (15, 60)
        }
        
        for col, (min_val, max_val) in outlier_threshold.items():
            if col in self.df.columns:
                removed = len(self.df[(self.df[col] < min_val) | (self.df[col] > max_val)])
                if removed > 0:
                    print(f"Removing {removed} outliers from {col}")
                    self.df = self.df[(self.df[col] >= min_val) & (self.df[col] <= max_val)]
        
        print(f"Records after cleaning: {len(self.df)}")
        return self
    
    def anonymize_data(self):
        """Add patient IDs and anonymize"""
        print("\nAnonymizing data...")
        
        # Generate patient IDs
        self.df['patient_id'] = [f"PT-{i:05d}" for i in range(1, len(self.df) + 1)]
        
        # Add timestamp
        self.df['ingestion_timestamp'] = int(datetime.utcnow().timestamp())
        
        # Reorder columns
        cols = ['patient_id', 'ingestion_timestamp'] + [col for col in self.df.columns if col not in ['patient_id', 'ingestion_timestamp']]
        self.df = self.df[cols]
        
        print("Anonymization complete")
        return self
    
    def engineer_features(self):
        """Create derived features for analysis"""
        print("\nEngineering features...")
        
        # Risk score (0-1 scale)
        self.df['risk_score'] = (
            (self.df['Glucose'] / 200) * 0.3 +
            (self.df['BMI'] / 50) * 0.2 +
            (self.df['Age'] / 100) * 0.2 +
            (self.df['BloodPressure'] / 150) * 0.15 +
            (self.df['DiabetesPedigreeFunction']) * 0.15
        ).clip(0, 1)
        
        # Risk level categories
        self.df['risk_level'] = pd.cut(
            self.df['risk_score'],
            bins=[0, 0.3, 0.5, 0.7, 1.0],
            labels=['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
        )
        
        # Age groups
        self.df['age_group'] = pd.cut(
            self.df['Age'],
            bins=[0, 30, 40, 50, 60, 100],
            labels=['<30', '30-40', '40-50', '50-60', '60+']
        )
        
        # BMI categories
        self.df['bmi_category'] = pd.cut(
            self.df['BMI'],
            bins=[0, 18.5, 25, 30, 100],
            labels=['Underweight', 'Normal', 'Overweight', 'Obese']
        )
        
        print("Feature engineering complete")
        return self
    
    def generate_statistics(self):
        """Calculate dataset statistics"""
        print("\nGenerating statistics...")
        
        self.stats = {
            'total_patients': len(self.df),
            'diabetes_prevalence': float(self.df['Outcome'].mean()),
            'avg_age': float(self.df['Age'].mean()),
            'avg_glucose': float(self.df['Glucose'].mean()),
            'avg_bmi': float(self.df['BMI'].mean()),
            'risk_distribution': {
                str(k): int(v) for k, v in self.df['risk_level'].value_counts().to_dict().items()
            },
            'age_distribution': {
                str(k): int(v) for k, v in self.df['age_group'].value_counts().to_dict().items()
            },
            'processing_timestamp': datetime.utcnow().isoformat()
        }
        
        print("Statistics:")
        print(f"  Total patients: {self.stats['total_patients']}")
        print(f"  Diabetes prevalence: {self.stats['diabetes_prevalence']:.1%}")
        print(f"  Average age: {self.stats['avg_age']:.1f}")
        print(f"  Average glucose: {self.stats['avg_glucose']:.1f}")
        print(f"  Risk distribution: {self.stats['risk_distribution']}")
        
        return self
    
    def save_local(self):
        """Save processed data locally"""
        print(f"\nSaving to {OUTPUT_FILE}...")
        
        self.df.to_csv(OUTPUT_FILE, index=False)
        
        # Save statistics
        stats_file = DATA_DIR / "statistics.json"
        with open(stats_file, 'w') as f:
            json.dump(self.stats, f, indent=2)
        
        print("Local save complete")
        return self
    
    def upload_to_s3(self):
        """Upload processed data to S3"""
        print(f"\nUploading to S3 bucket: {S3_BUCKET}...")
        
        try:
            s3_client = boto3.client('s3', region_name=AWS_REGION)
            
            # Upload CSV
            timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
            s3_key = f"processed/diabetes_processed_{timestamp}.csv"
            
            s3_client.upload_file(
                str(OUTPUT_FILE),
                S3_BUCKET,
                s3_key
            )
            print(f"Uploaded: s3://{S3_BUCKET}/{s3_key}")
            
            # Upload statistics
            stats_key = f"statistics/stats_{timestamp}.json"
            s3_client.put_object(
                Bucket=S3_BUCKET,
                Key=stats_key,
                Body=json.dumps(self.stats, indent=2),
                ContentType='application/json'
            )
            print(f"Uploaded: s3://{S3_BUCKET}/{stats_key}")
            
            print("S3 upload complete")
            
        except ClientError as e:
            print(f"ERROR: S3 upload failed - {e}")
            raise
        
        return self

def main():
    parser = argparse.ArgumentParser(description='AIER Data Pipeline')
    parser.add_argument('--upload', action='store_true', help='Upload to AWS S3')
    parser.add_argument('--skip-clean', action='store_true', help='Skip data cleaning')
    args = parser.parse_args()
    
    print("=" * 60)
    print("AIER Alert System - Data Pipeline")
    print("=" * 60)
    print("")
    
    try:
        pipeline = DataPipeline()
        pipeline.load_data()
        pipeline.validate_data()
        
        if not args.skip_clean:
            pipeline.clean_data()
        
        pipeline.anonymize_data()
        pipeline.engineer_features()
        pipeline.generate_statistics()
        pipeline.save_local()
        
        if args.upload:
            pipeline.upload_to_s3()
        else:
            print("\nSkipping S3 upload (use --upload flag to enable)")
        
        print("")
        print("=" * 60)
        print("Pipeline complete!")
        print("=" * 60)
        print("")
        print("Output files:")
        print(f"  {OUTPUT_FILE}")
        print(f"  {DATA_DIR / 'statistics.json'}")
        print("")
        
        if args.upload:
            print("Next steps:")
            print("  1. Verify S3 upload: aws s3 ls s3://{S3_BUCKET}/processed/")
            print("  2. Check Lambda logs for processing")
            print("  3. Query DynamoDB table")
        else:
            print("Next steps:")
            print("  1. Deploy infrastructure: cd terraform && terraform apply")
            print("  2. Re-run with --upload flag")
        
    except Exception as e:
        print(f"\nERROR: Pipeline failed - {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
