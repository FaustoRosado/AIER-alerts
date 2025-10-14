#!/usr/bin/env python3
"""
AI/ER Local LLM Server
Cybersecurity Capstone Project - Sprint 2

This server provides a secure, local interface to llama.cpp for emergency response scenarios.
Designed for educational purposes to demonstrate secure AI deployment practices.

Author: AI/ER Team
Date: October 2025
"""

import os
import json
import subprocess
import logging
from typing import Dict, List, Optional, Tuple
from flask import Flask, request, jsonify, render_template, Response
from flask_cors import CORS
import threading
import time
import re

# Configure logging for security auditing
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/llm_server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class LocalLLMServer:
    """
    Secure local LLM server wrapper for llama.cpp integration.

    This class demonstrates cybersecurity best practices:
    - Input validation and sanitization
    - Resource limits and monitoring
    - Secure subprocess management
    - Comprehensive logging for audit trails
    """

    def __init__(self, model_path: str = "models/llama-7b-q4_0.gguf"):
        """
        Initialize the local LLM server.

        Args:
            model_path: Path to the GGUF model file
        """
        self.model_path = model_path
        self.llama_cpp_path = "./llama.cpp/build/bin/llama-cli"
        self.validate_environment()

        # Security configurations
        self.max_prompt_length = 1000
        self.max_response_tokens = 150
        self.allowed_prompts = [
            "emergency", "security", "response", "incident", "protocol",
            "procedure", "safety", "medical", "technical", "cybersecurity"
        ]

        logger.info("LocalLLMServer initialized with model: %s", model_path)

    def validate_environment(self) -> None:
        """Validate that all required components are available."""
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"Model file not found: {self.model_path}")

        if not os.path.exists(self.llama_cpp_path):
            raise FileNotFoundError(f"llama-cli not found: {self.llama_cpp_path}")

        # Create logs directory
        os.makedirs("logs", exist_ok=True)

        logger.info("Environment validation completed successfully")

    def validate_prompt(self, prompt: str) -> Tuple[bool, str]:
        """
        Validate and sanitize user prompts for security.

        Args:
            prompt: User input prompt

        Returns:
            Tuple of (is_valid, reason/error_message)
        """
        if not prompt or len(prompt.strip()) == 0:
            return False, "Empty prompt not allowed"

        if len(prompt) > self.max_prompt_length:
            return False, f"Prompt too long. Maximum {self.max_prompt_length} characters allowed"

        # Check for potentially harmful content
        dangerous_patterns = [
            r'<script[^>]*>.*?</script>',
            r'javascript:',
            r'vbscript:',
            r'onload\s*=',
            r'onerror\s*=',
            r'eval\s*\(',
            r'exec\s*\(',
            r'system\s*\('
        ]

        prompt_lower = prompt.lower()
        for pattern in dangerous_patterns:
            if re.search(pattern, prompt_lower, re.IGNORECASE | re.DOTALL):
                logger.warning("Potentially dangerous content detected in prompt")
                return False, "Prompt contains potentially unsafe content"

        # Check for emergency/security relevance
        prompt_words = set(prompt_lower.split())
        if not any(word in prompt_words for word in self.allowed_prompts):
            logger.info("Prompt may not be emergency/security related")

        return True, "Prompt validation passed"

    def generate_response(self, prompt: str, context: str = "") -> Dict:
        """
        Generate a response using llama.cpp.

        Args:
            prompt: User question/prompt
            context: Additional context for the model

        Returns:
            Dictionary containing response and metadata
        """
        start_time = time.time()

        try:
            # Validate prompt
            is_valid, validation_message = self.validate_prompt(prompt)
            if not is_valid:
                logger.warning("Prompt validation failed: %s", validation_message)
                return {
                    "success": False,
                    "error": validation_message,
                    "response": "",
                    "processing_time": time.time() - start_time
                }

            # Construct the full prompt with context
            full_prompt = f"""You are an AI Emergency Response Assistant for cybersecurity students.
Context: {context}
Question: {prompt}
Provide a clear, accurate response focusing on security best practices:"""

            logger.info("Generating response for prompt length: %d", len(full_prompt))

            # Execute llama.cpp
            cmd = [
                self.llama_cpp_path,
                "-m", self.model_path,
                "-p", full_prompt,
                "-n", str(self.max_response_tokens),
                "--temp", "0.1",  # Low temperature for consistent responses
                "--top-p", "0.9",
                "--repeat-penalty", "1.1"
            ]

            logger.info("Executing llama.cpp with command: %s", " ".join(cmd))

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60,  # 60 second timeout
                cwd="llama.cpp"
            )

            if result.returncode != 0:
                logger.error("llama.cpp execution failed: %s", result.stderr)
                return {
                    "success": False,
                    "error": "Model execution failed",
                    "response": "",
                    "processing_time": time.time() - start_time
                }

            response = result.stdout.strip()
            processing_time = time.time() - start_time

            logger.info("Response generated successfully in %.2f seconds", processing_time)

            return {
                "success": True,
                "response": response,
                "prompt_tokens": len(full_prompt.split()),
                "response_tokens": len(response.split()),
                "processing_time": processing_time,
                "model": os.path.basename(self.model_path)
            }

        except subprocess.TimeoutExpired:
            logger.error("Model execution timed out")
            return {
                "success": False,
                "error": "Response generation timed out",
                "response": "",
                "processing_time": time.time() - start_time
            }
        except Exception as e:
            logger.error("Unexpected error during response generation: %s", str(e))
            return {
                "success": False,
                "error": "Internal server error",
                "response": "",
                "processing_time": time.time() - start_time
            }

# Flask application setup
app = Flask(__name__)
CORS(app)  # Enable CORS for development

# Global LLM server instance
llm_server = None

def initialize_llm_server():
    """Initialize the LLM server with proper error handling."""
    global llm_server

    try:
        model_path = os.getenv("MODEL_PATH", "models/llama-7b-q4_0.gguf")
        llm_server = LocalLLMServer(model_path)
        logger.info("LLM server initialized successfully")
        return True
    except Exception as e:
        logger.error("Failed to initialize LLM server: %s", str(e))
        return False

@app.route('/')
def index():
    """Serve the main interface."""
    return render_template('index.html')

@app.route('/health')
def health_check():
    """Health check endpoint for monitoring."""
    return jsonify({
        "status": "healthy",
        "model_loaded": llm_server is not None,
        "timestamp": time.time()
    })

@app.route('/api/generate', methods=['POST'])
def generate():
    """Generate response from local LLM."""
    if not llm_server:
        return jsonify({
            "success": False,
            "error": "LLM server not initialized"
        }), 503

    try:
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "error": "No JSON data provided"
            }), 400

        prompt = data.get('prompt', '').strip()
        context = data.get('context', '').strip()

        if not prompt:
            return jsonify({
                "success": False,
                "error": "Prompt is required"
            }), 400

        # Generate response
        result = llm_server.generate_response(prompt, context)

        # Log the request for security auditing
        logger.info("API request processed - Success: %s, Tokens: %s",
                   result.get("success"),
                   result.get("response_tokens", 0))

        return jsonify(result)

    except Exception as e:
        logger.error("API error: %s", str(e))
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

@app.route('/api/models', methods=['GET'])
def list_models():
    """List available models."""
    try:
        models_dir = "models"
        if os.path.exists(models_dir):
            models = [f for f in os.listdir(models_dir) if f.endswith('.gguf')]
        else:
            models = []

        return jsonify({
            "success": True,
            "models": models,
            "current_model": getattr(llm_server, 'model_path', 'None') if llm_server else 'None'
        })
    except Exception as e:
        logger.error("Error listing models: %s", str(e))
        return jsonify({
            "success": False,
            "error": "Failed to list models"
        }), 500

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({
        "success": False,
        "error": "Endpoint not found"
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error("Internal server error: %s", str(error))
    return jsonify({
        "success": False,
        "error": "Internal server error"
    }), 500

if __name__ == "__main__":
    logger.info("Starting AI/ER Local LLM Server")

    # Initialize the LLM server
    if not initialize_llm_server():
        logger.error("Failed to initialize LLM server. Exiting.")
        exit(1)

    # Start the Flask application
    app.run(
        host='127.0.0.1',
        port=5000,
        debug=False,  # Disable debug mode for security
        threaded=True
    )
