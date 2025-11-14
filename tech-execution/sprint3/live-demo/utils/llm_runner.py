"""
Local LLM Runner - Phi-3 Mini for Healthcare Vitals Analysis

CONCEPT: VitalsAnalyzer (using local LLM)
PURPOSE: Analyze patient vital signs offline for ER alert system

OPERATIONAL PRINCIPLE (from paper Section 2):
    After receiving vitals:
    - Construct structured prompt (forces JSON output)
    - Invoke local Phi-3 LLM (no cloud dependency)
    - Parse LLM response to structured alert
    - Fallback to rule-based if LLM fails (resilience)

INDEPENDENCE (paper Section 2):
    This concept has NO dependencies on other concepts
    Dependencies: llama.cpp (lower-level service), local filesystem
    
RESILIENCE PATTERN (from AI-ER architecture docs):
    Local inference ensures system works during network outages
    (Ascension Health ransomware scenario - system stays operational)
"""

import json
import time
from typing import Dict, Optional
import os
import re


class LLMRunner:
    """
    Handles local LLM inference using llama-cpp-python
    
    Supports: Phi-3 Mini, Llama 3.2, Mistral 7B
    Default: Phi-3 Mini (best for healthcare reasoning)
    """
    
    def __init__(self, model_path: Optional[str] = None):
        """
        Initialize LLM model
        
        Model loads on init (takes ~2-5 seconds)
        Then inference is fast (~0.5s per request)
        
        Model path resolution (works in Docker, Colab, local):
        1. Use provided path
        2. Check MODEL_PATH env var
        3. Check /opt/models (Docker)
        4. Check ./models (local/Colab)
        5. Check ~/.cache/models (user cache)
        """
        # Resolve model path - works in all environments
        if model_path:
            self.model_path = model_path
        elif os.environ.get('MODEL_PATH'):
            self.model_path = os.environ.get('MODEL_PATH')
        elif os.path.exists('/opt/models/Phi-3-mini-4k-instruct-q4.gguf'):
            self.model_path = '/opt/models/Phi-3-mini-4k-instruct-q4.gguf'
        elif os.path.exists('./models/Phi-3-mini-4k-instruct-q4.gguf'):
            self.model_path = './models/Phi-3-mini-4k-instruct-q4.gguf'
        elif os.path.exists(os.path.expanduser('~/.cache/models/Phi-3-mini-4k-instruct-q4.gguf')):
            self.model_path = os.path.expanduser('~/.cache/models/Phi-3-mini-4k-instruct-q4.gguf')
        else:
            # Default to local models directory
            self.model_path = './models/Phi-3-mini-4k-instruct-q4.gguf'
        
        self.llm = None
        self.model_loaded = False
        self.load_error = None
        
        # Try to load model
        self._load_model()
    
    
    def _load_model(self):
        """Load LLM model into memory"""
        try:
            from llama_cpp import Llama
            
            print(f"Loading model from {self.model_path}...")
            
            if not os.path.exists(self.model_path):
                self.load_error = f"Model file not found: {self.model_path}"
                print(f"ERROR: {self.load_error}")
                return
            
            self.llm = Llama(
                model_path=self.model_path,
                n_ctx=2048,           # Context window
                n_threads=4,          # CPU threads
                n_gpu_layers=0,       # CPU only (for compatibility)
                verbose=False
            )
            
            self.model_loaded = True
            print("Model loaded successfully!")
            
        except ImportError:
            self.load_error = "llama-cpp-python not installed. Run: pip install llama-cpp-python"
            print(f"ERROR: {self.load_error}")
        except Exception as e:
            self.load_error = str(e)
            print(f"ERROR loading model: {e}")
    
    
    def is_ready(self) -> bool:
        """Check if model is loaded and ready"""
        return self.model_loaded
    
    
    def analyze_vitals(self, vitals: Dict) -> Dict:
        """
        Analyze patient vitals using local LLM
        
        Input vitals dict with: heart_rate, bp_systolic, oxygen_saturation, etc
        Returns: Structured clinical assessment
        """
        
        if not self.model_loaded:
            # Fallback to rule-based if LLM not available
            return self._fallback_analysis(vitals)
        
        # Construct prompt
        prompt = self._create_healthcare_prompt(vitals)
        
        # Run inference
        start_time = time.time()
        output = self._run_inference(prompt)
        inference_time = time.time() - start_time
        
        # Parse result
        result = self._parse_llm_output(output, vitals)
        result['inference_time'] = round(inference_time, 3)
        result['model_used'] = 'phi-3-mini'
        
        return result
    
    
    def _create_healthcare_prompt(self, vitals: Dict) -> str:
        """
        Create structured prompt for Phi-3
        
        Key: Force clean JSON output with human-readable clinical language
        """
        
        patient_id = vitals.get('patient_id', 'UNKNOWN')
        hr = vitals.get('heart_rate', 'N/A')
        bp_sys = vitals.get('bp_systolic', 'N/A')
        bp_dia = vitals.get('bp_diastolic', 'N/A')
        o2 = vitals.get('oxygen_saturation', 'N/A')
        rr = vitals.get('respiratory_rate', 'N/A')
        temp = vitals.get('temperature', 'N/A')
        
        prompt = f"""<|system|>
You are an expert Emergency Room triage nurse. Analyze patient vital signs and provide a clear, structured clinical assessment. Your response must be valid JSON only, with human-readable text in the fields.<|end|>
<|user|>
Patient ID: {patient_id}

CURRENT VITAL SIGNS:
- Heart Rate: {hr} bpm (normal range: 60-100 bpm)
- Blood Pressure: {bp_sys}/{bp_dia} mmHg (normal: <120/80)
- Oxygen Saturation: {o2}% (normal: 95-100%)
- Respiratory Rate: {rr} breaths/min (normal: 12-20)
- Temperature: {temp}°C (normal: 36.5-37.5°C)

Provide your assessment as JSON with these exact fields:
{{
  "urgency": "NORMAL" or "MODERATE" or "CRITICAL",
  "primary_concern": "Clear, concise clinical concern in plain English",
  "reasoning": "2-3 sentence explanation of your clinical reasoning in plain English",
  "abnormal_vitals": ["heart_rate", "blood_pressure", "oxygen_saturation", "respiratory_rate", "temperature"],
  "recommended_actions": ["Action 1 in plain English", "Action 2 in plain English"],
  "confidence_score": 0.85
}}

Respond with ONLY the JSON object, no other text.<|end|>
<|assistant|>
{{"""
        
        return prompt
    
    
    def _run_inference(self, prompt: str) -> str:
        """
        Run LLM inference with optimized parameters
        
        Parameters explained (paper Section 7.3 on LLM generation):
        - temperature 0.1: Low temp for consistent, deterministic outputs
        - top_p 0.9: Nucleus sampling balances quality and speed
        - repeat_penalty 1.1: Prevents repetitive medical terminology
        - max_tokens 512: Enough for structured clinical assessment
        - stop sequences: Phi-3 specific tokens to end generation cleanly
        """
        try:
            output = self.llm(
                prompt,
                max_tokens=512,
                temperature=0.1,      # Low for consistency (clinical decisions)
                top_p=0.9,            # Nucleus sampling
                repeat_penalty=1.1,   # Reduce repetition
                stop=["<|end|>", "</s>", "\n\n\n"],  # Phi-3 stop tokens
                echo=False            # Don't echo prompt in output
            )
            
            return output['choices'][0]['text']
        except Exception as e:
            print(f"Inference error: {e}")
            return "{\"error\": \"Inference failed\"}"
    
    
    def _parse_llm_output(self, output: str, vitals: Dict) -> Dict:
        """
        Parse LLM JSON output with robust extraction
        
        Handles cases where LLM adds extra text before/after JSON
        """
        try:
            # Clean output - remove leading/trailing whitespace
            output = output.strip()
            
            # Find JSON object boundaries
            start_idx = output.find('{')
            end_idx = output.rfind('}')
            
            if start_idx == -1 or end_idx == -1 or end_idx <= start_idx:
                raise ValueError("No valid JSON found in output")
            
            # Extract JSON
            json_text = output[start_idx:end_idx + 1]
            
            # Parse JSON
            result = json.loads(json_text)
            
            # Validate required fields
            required_fields = ['urgency', 'primary_concern', 'reasoning', 'abnormal_vitals', 'recommended_actions', 'confidence_score']
            for field in required_fields:
                if field not in result:
                    raise ValueError(f"Missing required field: {field}")
            
            # Ensure urgency is valid
            if result['urgency'] not in ['NORMAL', 'MODERATE', 'CRITICAL']:
                result['urgency'] = 'MODERATE'  # Default to moderate if invalid
            
            # Ensure lists are actually lists
            if not isinstance(result.get('abnormal_vitals', []), list):
                result['abnormal_vitals'] = []
            if not isinstance(result.get('recommended_actions', []), list):
                result['recommended_actions'] = ['Monitor patient']
            
            # Ensure confidence is a number
            if not isinstance(result.get('confidence_score'), (int, float)):
                result['confidence_score'] = 0.75
            
            # Clamp confidence to 0-1
            result['confidence_score'] = max(0.0, min(1.0, float(result['confidence_score'])))
            
            result['analysis_method'] = 'llm'
            return result
            
        except Exception as e:
            print(f"[WARN] Failed to parse LLM output: {e}")
            print(f"[WARN] Raw output: {output[:200]}...")
            # If parsing fails, use fallback
            return self._fallback_analysis(vitals)
    
    
    def _fallback_analysis(self, vitals: Dict) -> Dict:
        """
        Rule-based fallback if LLM unavailable
        
        Resilience pattern: System still works without AI
        """
        
        abnormal = []
        concerns = []
        
        # Simple rule-based checks
        hr = vitals.get('heart_rate', 75)
        if hr < 60:
            abnormal.append('heart_rate')
            concerns.append('Bradycardia')
        elif hr > 100:
            abnormal.append('heart_rate')
            concerns.append('Tachycardia')
        
        bp_sys = vitals.get('bp_systolic', 120)
        if bp_sys > 140:
            abnormal.append('blood_pressure')
            concerns.append('Hypertension')
        elif bp_sys < 90:
            abnormal.append('blood_pressure')
            concerns.append('Hypotension')
        
        o2 = vitals.get('oxygen_saturation', 98)
        if o2 < 90:
            abnormal.append('oxygen_saturation')
            concerns.append('Critical hypoxemia')
        elif o2 < 95:
            abnormal.append('oxygen_saturation')
            concerns.append('Low oxygen saturation')
        
        # Determine urgency
        if o2 < 90 or bp_sys < 90 or hr > 140:
            urgency = 'CRITICAL'
        elif len(abnormal) > 0:
            urgency = 'MODERATE'
        else:
            urgency = 'NORMAL'
        
        return {
            'urgency': urgency,
            'primary_concern': ', '.join(concerns) if concerns else 'All vitals normal',
            'reasoning': 'Rule-based analysis (LLM unavailable)',
            'abnormal_vitals': abnormal,
            'recommended_actions': ['Immediate assessment'] if urgency == 'CRITICAL' else ['Monitor'],
            'confidence_score': 0.75,
            'analysis_method': 'rule_based',
            'inference_time': 0.001
        }

