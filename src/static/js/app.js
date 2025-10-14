/**
 * AI/ER Local LLM Interface JavaScript
 * Cybersecurity Capstone Project - Sprint 2
 *
 * This script handles the front-end interactions for the local LLM emergency response system.
 * Demonstrates secure front-end practices and user experience design.
 */

class AIERInterface {
    constructor() {
        this.initializeElements();
        this.bindEvents();
        this.checkConnection();
        this.selectedUrgency = 'high';
        this.selectedScenario = '';
        this.contextData = {};

        // Security: Token counting for input validation
        this.maxPromptLength = 1000;
        this.promptTokens = 0;

        console.log('AI/ER Interface initialized');
    }

    initializeElements() {
        // Context panel elements
        this.scenarioSelect = document.getElementById('scenarioSelect');
        this.urgencyButtons = document.querySelectorAll('.urgency-btn');
        this.contextInput = document.getElementById('contextInput');
        this.contextDisplay = document.getElementById('contextDisplay');

        // Chat elements
        this.chatMessages = document.getElementById('chatMessages');
        this.promptInput = document.getElementById('promptInput');
        this.sendButton = document.getElementById('sendButton');
        this.clearButton = document.getElementById('clearButton');
        this.resetContextButton = document.getElementById('resetContextButton');
        this.tokenCount = document.getElementById('tokenCount');

        // Status elements
        this.statusDot = document.getElementById('statusDot');
        this.statusText = document.getElementById('statusText');
        this.modelStatus = document.getElementById('modelStatus');

        // Loading overlay
        this.loadingOverlay = document.getElementById('loadingOverlay');
    }

    bindEvents() {
        // Context panel events
        this.scenarioSelect?.addEventListener('change', (e) => {
            this.selectedScenario = e.target.value;
            this.updateContext();
        });

        this.urgencyButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.urgencyButtons.forEach(b => b.classList.remove('active'));
                e.target.classList.add('active');
                this.selectedUrgency = e.target.dataset.level;
                this.updateContext();
            });
        });

        this.contextInput?.addEventListener('input', (e) => {
            this.contextData.customContext = e.target.value;
            this.updateContext();
        });

        // Chat events
        this.promptInput?.addEventListener('input', (e) => {
            this.updateTokenCount(e.target.value);
            this.validateInput();
        });

        this.promptInput?.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
                e.preventDefault();
                this.sendMessage();
            }
        });

        this.sendButton?.addEventListener('click', () => {
            this.sendMessage();
        });

        this.clearButton?.addEventListener('click', () => {
            this.clearChat();
        });

        this.resetContextButton?.addEventListener('click', () => {
            this.resetContext();
        });

        // Global keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.hideLoading();
            }
        });
    }

    async checkConnection() {
        try {
            const response = await fetch('/health');
            const data = await response.json();

            if (data.status === 'healthy') {
                this.statusDot.classList.add('connected');
                this.statusText.textContent = 'Connected';
                this.modelStatus.textContent = 'Ready';
                this.modelStatus.classList.add('connected');
            } else {
                this.statusText.textContent = 'Server Error';
                this.modelStatus.textContent = 'Error';
            }
        } catch (error) {
            console.error('Connection check failed:', error);
            this.statusText.textContent = 'Connection Failed';
            this.modelStatus.textContent = 'Offline';
        }
    }

    updateContext() {
        const scenarioText = this.getScenarioText(this.selectedScenario);
        const urgencyText = this.getUrgencyText(this.selectedUrgency);
        const customContext = this.contextData.customContext || '';

        let context = `Scenario: ${scenarioText}, Urgency: ${urgencyText}`;
        if (customContext) {
            context += `, Details: ${customContext}`;
        }

        this.contextDisplay.textContent = context;
        this.contextData = {
            scenario: this.selectedScenario,
            urgency: this.selectedUrgency,
            customContext: customContext,
            contextString: context
        };
    }

    getScenarioText(scenario) {
        const scenarios = {
            'cybersecurity': 'Cybersecurity Incident Response',
            'medical': 'Medical Emergency',
            'technical': 'Technical Infrastructure Failure',
            'security': 'Physical Security Threat',
            'custom': 'Custom Emergency Scenario'
        };
        return scenarios[scenario] || 'General Emergency';
    }

    getUrgencyText(urgency) {
        const urgencies = {
            'low': 'Low Priority',
            'medium': 'Medium Priority',
            'high': 'High Priority',
            'critical': 'Critical - Immediate Action Required'
        };
        return urgencies[urgency] || 'Medium Priority';
    }

    updateTokenCount(text) {
        // Simple token estimation (words + punctuation)
        const words = text.trim().split(/\s+/).filter(word => word.length > 0);
        this.promptTokens = Math.ceil(words.length * 1.3); // Rough estimation
        this.tokenCount.textContent = this.promptTokens;

        // Visual feedback for token limits
        if (this.promptTokens > this.maxPromptLength) {
            this.tokenCount.style.color = 'var(--danger-color)';
        } else if (this.promptTokens > this.maxPromptLength * 0.8) {
            this.tokenCount.style.color = 'var(--warning-color)';
        } else {
            this.tokenCount.style.color = 'var(--text-muted)';
        }
    }

    validateInput() {
        const text = this.promptInput.value.trim();

        if (text.length === 0) {
            this.sendButton.disabled = true;
            return false;
        }

        if (this.promptTokens > this.maxPromptLength) {
            this.sendButton.disabled = true;
            this.showError('Prompt too long. Please keep under 1000 tokens.');
            return false;
        }

        this.sendButton.disabled = false;
        return true;
    }

    async sendMessage() {
        if (!this.validateInput()) return;

        const prompt = this.promptInput.value.trim();
        const context = this.contextData.contextString || '';

        // Add user message to chat
        this.addMessage('user', prompt);

        // Clear input
        this.promptInput.value = '';
        this.updateTokenCount('');
        this.sendButton.disabled = true;

        // Show loading
        this.showLoading('Generating secure response...');

        try {
            const response = await fetch('/api/generate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    prompt: prompt,
                    context: context
                })
            });

            const data = await response.json();

            if (data.success) {
                this.addMessage('assistant', data.response);
            } else {
                this.addMessage('system', `Error: ${data.error}`);
            }
        } catch (error) {
            console.error('API request failed:', error);
            this.addMessage('system', 'Connection error. Please check if the server is running.');
        } finally {
            this.hideLoading();
        }
    }

    addMessage(type, content) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${type}-message`;

        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        contentDiv.textContent = content;

        messageDiv.appendChild(contentDiv);
        this.chatMessages.appendChild(messageDiv);

        // Scroll to bottom
        this.chatMessages.scrollTop = this.chatMessages.scrollHeight;

        // Log for security auditing (in production, send to secure logging service)
        console.log(`[${new Date().toISOString()}] ${type}: ${content.substring(0, 100)}...`);
    }

    clearChat() {
        this.chatMessages.innerHTML = `
            <div class="message system-message">
                <div class="message-content">
                    <strong>Welcome to AI/ER - Local LLM Emergency Response System</strong><br>
                    This system runs entirely on your local machine for maximum security and privacy.
                    Describe your emergency situation, and I'll provide guidance based on cybersecurity best practices.
                </div>
            </div>
        `;
    }

    resetContext() {
        this.scenarioSelect.value = '';
        this.selectedScenario = '';
        this.urgencyButtons.forEach(btn => btn.classList.remove('active'));
        document.querySelector('[data-level="high"]').classList.add('active');
        this.selectedUrgency = 'high';
        this.contextInput.value = '';
        this.contextData = {};
        this.updateContext();
    }

    showLoading(message = 'Processing...') {
        const loadingText = this.loadingOverlay.querySelector('.loading-text');
        if (loadingText) {
            loadingText.textContent = message;
        }
        this.loadingOverlay.classList.add('active');
    }

    hideLoading() {
        this.loadingOverlay.classList.remove('active');
    }

    showError(message) {
        this.addMessage('system', `⚠️ ${message}`);
    }

    // Security utility methods
    sanitizeInput(input) {
        // Basic input sanitization
        return input
            .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
            .replace(/javascript:/gi, '')
            .replace(/on\w+\s*=/gi, '')
            .trim();
    }

    validateFileUpload(file) {
        // File upload security validation
        const maxSize = 10 * 1024 * 1024; // 10MB
        const allowedTypes = ['text/plain', 'application/pdf'];

        if (file.size > maxSize) {
            throw new Error('File too large. Maximum size is 10MB.');
        }

        if (!allowedTypes.includes(file.type)) {
            throw new Error('File type not allowed.');
        }

        return true;
    }
}

// Initialize the interface when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.aierInterface = new AIERInterface();
});

// Global error handler for security monitoring
window.addEventListener('error', (e) => {
    console.error('Global error:', e.error);
    // In production, send to secure logging service
});

// Performance monitoring
window.addEventListener('load', () => {
    const loadTime = performance.now();
    console.log(`AI/ER Interface loaded in ${loadTime.toFixed(2)}ms`);
});
