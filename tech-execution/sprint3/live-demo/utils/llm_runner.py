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
        """
        self.model_path = model_path or os.environ.get(
            'MODEL_PATH',
            '/opt/models/Phi-3-mini-4k-instruct-q4.gguf'
        )
        
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
        
        Key: Force JSON output with specific schema
        """
        
        prompt = f"""<|system|>
You are an expert Emergency Room triage nurse. Analyze patient vital signs and provide structured assessment. Respond ONLY with valid JSON.<|end|>
<|user|>
CURRENT VITAL SIGNS:
- Heart Rate: {vitals.get('heart_rate', 'N/A')} bpm (normal: 60-100)
- Blood Pressure: {vitals.get('bp_systolic', 'N/A')}/{vitals.get('bp_diastolic', 'N/A')} mmHg (normal: 120/80)
- Oxygen Saturation: {vitals.get('oxygen_saturation', 'N/A')}% (normal: 95-100%)
- Respiratory Rate: {vitals.get('respiratory_rate', 'N/A')}/min (normal: 12-20)
- Temperature: {vitals.get('temperature', 'N/A')}°C (normal: 36.5-37.5)

Respond with JSON:
{{
  "urgency": "NORMAL/MODERATE/CRITICAL",
  "primary_concern": "brief description",
  "reasoning": "clinical reasoning 2-3 sentences",
  "abnormal_vitals": ["list"],
  "recommended_actions": ["action1", "action2"],
  "confidence_score": 0.0-1.0
}}<|end|>
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
        """Parse LLM JSON output"""
        try:
            # Try to extract JSON
            json_text = "{" + output.split("}")[0] + "}"
            result = json.loads(json_text)
            result['analysis_method'] = 'llm'
            return result
        except:
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

