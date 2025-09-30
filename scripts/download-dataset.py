#!/usr/bin/env python3
"""
AIER Alert System - Kaggle Dataset Downloader
Downloads the diabetes dataset from Kaggle for visualization
"""

import os
import sys
from pathlib import Path

try:
    from kaggle.api.kaggle_api_extended import KaggleApi
except ImportError:
    print("ERROR: Kaggle package not installed")
    print("Install with: pip install kaggle")
    sys.exit(1)

# Configuration
DATASET_NAME = "hasibur013/diabetes-dataset"
OUTPUT_DIR = Path(__file__).parent.parent / "data"
OUTPUT_FILE = OUTPUT_DIR / "diabetes.csv"

def check_kaggle_credentials():
    """Verify Kaggle API credentials are configured"""
    kaggle_json = Path.home() / ".kaggle" / "kaggle.json"
    
    if not kaggle_json.exists():
        print("ERROR: Kaggle credentials not found")
        print("")
        print("To set up Kaggle API:")
        print("1. Create account at https://www.kaggle.com")
        print("2. Go to Account → API → Create New API Token")
        print("3. Move kaggle.json to:")
        print(f"   {kaggle_json.parent}")
        print("")
        return False
    
    print(f"Kaggle credentials found at: {kaggle_json}")
    return True

def download_dataset():
    """Download diabetes dataset from Kaggle"""
    
    print("=" * 60)
    print("AIER Alert System - Dataset Download")
    print("=" * 60)
    print("")
    
    # Check credentials
    if not check_kaggle_credentials():
        sys.exit(1)
    
    # Create output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {OUTPUT_DIR}")
    print("")
    
    # Initialize Kaggle API
    print("Initializing Kaggle API...")
    api = KaggleApi()
    api.authenticate()
    print("Authentication successful")
    print("")
    
    # Download dataset
    print(f"Downloading dataset: {DATASET_NAME}")
    print("This may take a few moments...")
    
    try:
        api.dataset_download_files(
            DATASET_NAME,
            path=OUTPUT_DIR,
            unzip=True
        )
        print("Download complete")
        print("")
    except Exception as e:
        print(f"ERROR: Download failed - {e}")
        sys.exit(1)
    
    # Verify file exists
    if OUTPUT_FILE.exists():
        file_size = OUTPUT_FILE.stat().st_size
        print(f"Dataset saved to: {OUTPUT_FILE}")
        print(f"File size: {file_size:,} bytes")
        print("")
        
        # Show file preview
        print("First 5 lines of dataset:")
        print("-" * 60)
        with open(OUTPUT_FILE, 'r') as f:
            for i, line in enumerate(f):
                if i < 5:
                    print(line.strip())
                else:
                    break
        print("-" * 60)
        print("")
        
        print("SUCCESS: Dataset ready for processing")
        print("")
        print("Next steps:")
        print("  1. Run data pipeline: python scripts/data-pipeline.py")
        print("  2. Deploy infrastructure: cd terraform && terraform apply")
        print("")
    else:
        print("ERROR: Downloaded file not found")
        sys.exit(1)

if __name__ == "__main__":
    download_dataset()
