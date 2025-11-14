#!/usr/bin/env python3
"""
Download Phi-3 Mini model for local LLM inference

Automatically downloads from HuggingFace if not present
"""

import os
import requests
from tqdm import tqdm
import sys


MODEL_URL = "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf"
MODEL_NAME = "Phi-3-mini-4k-instruct-q4.gguf"

# Determine model directory based on environment
# Works in Docker, Colab, and local
if os.environ.get('MODEL_PATH'):
    MODEL_DIR = os.path.dirname(os.environ.get('MODEL_PATH'))
    MODEL_PATH = os.environ.get('MODEL_PATH')
elif os.path.exists('/opt/models'):
    MODEL_DIR = '/opt/models'
    MODEL_PATH = os.path.join(MODEL_DIR, MODEL_NAME)
elif os.path.exists('./models'):
    MODEL_DIR = './models'
    MODEL_PATH = os.path.join(MODEL_DIR, MODEL_NAME)
else:
    # Default to local models directory
    MODEL_DIR = './models'
    MODEL_PATH = os.path.join(MODEL_DIR, MODEL_NAME)


def download_file(url, destination):
    """Download file with progress bar"""
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    
    print(f"downloading {MODEL_NAME} ({total_size / 1024 / 1024:.1f} mb)")
    print("this will take 3-5 minutes depending on connection speed...")
    
    with open(destination, 'wb') as f:
        with tqdm(total=total_size, unit='B', unit_scale=True) as pbar:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    pbar.update(len(chunk))
    
    print(f"download complete: {destination}")


def main():
    # Create directory if doesn't exist
    os.makedirs(MODEL_DIR, exist_ok=True)
    
    # Check if model already exists
    if os.path.exists(MODEL_PATH):
        size_mb = os.path.getsize(MODEL_PATH) / 1024 / 1024
        print(f"model already downloaded: {MODEL_PATH} ({size_mb:.1f} mb)")
        print("skipping download.")
        return 0
    
    # Download model
    try:
        download_file(MODEL_URL, MODEL_PATH)
        print("model ready for use!")
        return 0
    except Exception as e:
        print(f"error downloading model: {e}")
        print("\nmanual download instructions:")
        print(f"1. create directory: mkdir -p {MODEL_DIR}")
        print(f"2. download from: {MODEL_URL}")
        print(f"3. save as: {MODEL_PATH}")
        return 1


if __name__ == "__main__":
    sys.exit(main())

