#!/usr/bin/env node
/**
 * Zero-Trust Hybrid AI Pipeline - Orchestrator MCP Server
 * ========================================================
 * 
 * This MCP server enables Claude Desktop (and other MCP-compatible clients)
 * to interact with your distributed AI inference mesh. It provides tools for:
 * 
 * 1. Routing inference requests to the optimal backend
 * 2. Checking backend status and health
 * 3. Running validation passes on generated content
 * 4. Creating embeddings for RAG applications
 * 
 * The server communicates with your local orchestrator API, which in turn
 * routes requests to Aegis (fast inference) or AIER-Admin (specialized models).
 * 
 * Installation:
 *   npm install
 *   node index.js
 * 
 * Or via Claude Desktop config (see claude_desktop_config.json)
 */

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';

// Configuration from environment
const ORCHESTRATOR_URL = process.env.ORCHESTRATOR_URL || 'http://localhost:8000';

// Initialize MCP Server
const server = new McpServer({
  name: 'hybrid-ai-orchestrator',
  version: '1.0.0',
  description: 'MCP server for distributed AI inference orchestration'
});

// ============================================================================
// Tool: Check Backend Status
// ============================================================================

server.tool(
  'check_backends',
  {
    description: `Check the status of all AI inference backends in the distributed mesh.
    
Returns information about:
- Aegis (RTX 4080 Super): Primary high-speed inference
- AIER-Admin (Ryzen AI 395): Multi-model specialist  
- Mac Mini (M4 Pro): Secondary inference node

Use this to verify backends are online before routing requests.`,
    inputSchema: z.object({
      refresh: z.boolean().optional().describe('Force refresh of backend status')
    })
  },
  async ({ refresh = false }) => {
    try {
      const response = await fetch(`${ORCHESTRATOR_URL}/backends?refresh=${refresh}`);
      if (!response.ok) {
        throw new Error(`Orchestrator returned ${response.status}`);
      }
      
      const data = await response.json();
      
      // Format the response for readability
      let statusReport = '## Backend Status Report\n\n';
      
      for (const backend of data.backends) {
        const emoji = backend.status === 'online' ? '🟢' : '🔴';
        statusReport += `### ${emoji} ${backend.name}\n`;
        statusReport += `- **Status:** ${backend.status}\n`;
        statusReport += `- **Latency:** ${backend.latency_ms || 'N/A'} ms\n`;
        statusReport += `- **Capabilities:** ${backend.config?.capabilities?.join(', ') || 'N/A'}\n`;
        statusReport += `- **Typical Speed:** ${backend.config?.typical_speed || 'N/A'}\n\n`;
      }
      
      return {
        content: [{
          type: 'text',
          text: statusReport
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text', 
          text: `Error checking backends: ${error.message}\n\nMake sure the orchestrator is running at ${ORCHESTRATOR_URL}`
        }],
        isError: true
      };
    }
  }
);

// ============================================================================
// Tool: Inference Request
// ============================================================================

server.tool(
  'inference',
  {
    description: `Send an inference request through the distributed AI mesh.

The orchestrator will automatically route your request to the optimal backend:
- Code tasks → AIER-Admin (Qwen2.5-Coder)
- Fast general tasks → Aegis (Llama 3.1 8B)
- Validation → AIER-Admin (Phi-3 14B)

You can also specify a task_type to influence routing, or require_validation 
to have outputs verified by a second model.`,
    inputSchema: z.object({
      prompt: z.string().describe('The prompt or question to send'),
      task_type: z.enum(['general', 'code', 'validation', 'fast', 'embedding'])
        .optional()
        .describe('Hint for routing: general, code, validation, fast, or embedding'),
      require_validation: z.boolean()
        .optional()
        .describe('If true, validate the response with a second model'),
      system_prompt: z.string()
        .optional()
        .describe('Optional system prompt for context')
    })
  },
  async ({ prompt, task_type, require_validation = false, system_prompt }) => {
    try {
      const messages = [];
      
      if (system_prompt) {
        messages.push({ role: 'system', content: system_prompt });
      }
      messages.push({ role: 'user', content: prompt });
      
      const response = await fetch(`${ORCHESTRATOR_URL}/v1/chat/completions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages,
          task_type,
          require_validation,
          temperature: 0.7,
          max_tokens: 2048
        })
      });
      
      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Orchestrator error: ${error}`);
      }
      
      const data = await response.json();
      
      // Extract the response content
      const content = data.choices?.[0]?.message?.content || 'No response generated';
      const orchestration = data.orchestration || {};
      
      // Build response with metadata
      let result = content;
      
      // Add orchestration info
      result += '\n\n---\n';
      result += `*Processed by ${orchestration.backend_name || 'unknown'} `;
      result += `(${orchestration.model || 'unknown model'}) `;
      result += `in ${orchestration.latency_ms || '?'}ms*`;
      
      // Add validation results if present
      if (orchestration.validation) {
        const v = orchestration.validation;
        result += `\n\n**Validation:** ${v.valid ? '✅ Passed' : '⚠️ Issues found'}`;
        if (v.issues?.length > 0) {
          result += `\n- ${v.issues.join('\n- ')}`;
        }
      }
      
      return {
        content: [{
          type: 'text',
          text: result
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Inference error: ${error.message}`
        }],
        isError: true
      };
    }
  }
);

// ============================================================================
// Tool: Code Generation (Specialized)
// ============================================================================

server.tool(
  'generate_code',
  {
    description: `Generate code using the specialized Qwen2.5-Coder model on AIER-Admin.

This tool routes directly to the code-specialized model for best results on:
- Writing new functions/classes
- Refactoring existing code
- Code review and suggestions
- Bug fixes`,
    inputSchema: z.object({
      description: z.string().describe('What code to generate or modify'),
      language: z.string().optional().describe('Programming language (e.g., python, typescript)'),
      context: z.string().optional().describe('Existing code or context to consider'),
      validate: z.boolean().optional().describe('Validate the generated code with Phi-3')
    })
  },
  async ({ description, language = 'python', context, validate = true }) => {
    let prompt = `Generate ${language} code for the following:\n\n${description}`;
    
    if (context) {
      prompt += `\n\nExisting code context:\n\`\`\`${language}\n${context}\n\`\`\``;
    }
    
    prompt += '\n\nProvide clean, well-commented, production-ready code.';
    
    try {
      const response = await fetch(`${ORCHESTRATOR_URL}/v1/chat/completions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          messages: [{ role: 'user', content: prompt }],
          task_type: 'code',
          require_validation: validate,
          temperature: 0.3,  // Lower temp for code
          max_tokens: 4096
        })
      });
      
      if (!response.ok) {
        throw new Error(`Code generation failed: ${response.status}`);
      }
      
      const data = await response.json();
      const content = data.choices?.[0]?.message?.content || 'No code generated';
      const orchestration = data.orchestration || {};
      
      let result = content;
      result += `\n\n---\n*Generated by ${orchestration.model || 'Qwen2.5-Coder'}*`;
      
      if (orchestration.validation && !orchestration.validation.valid) {
        result += '\n\n⚠️ **Validation Issues:**\n';
        result += orchestration.validation.issues?.join('\n') || 'Unknown issues';
      }
      
      return {
        content: [{
          type: 'text',
          text: result
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Code generation error: ${error.message}`
        }],
        isError: true
      };
    }
  }
);

// ============================================================================
// Tool: Create Embeddings
// ============================================================================

server.tool(
  'create_embedding',
  {
    description: `Create text embeddings using the BGE-M3 model on AIER-Admin.

Useful for:
- Building RAG (Retrieval Augmented Generation) systems
- Semantic search
- Document similarity
- Clustering text`,
    inputSchema: z.object({
      text: z.string().describe('Text to create embedding for'),
      batch: z.array(z.string()).optional().describe('Multiple texts for batch embedding')
    })
  },
  async ({ text, batch }) => {
    try {
      const texts = batch || [text];
      
      const response = await fetch(`${ORCHESTRATOR_URL}/v1/embeddings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(texts)
      });
      
      if (!response.ok) {
        throw new Error(`Embedding creation failed: ${response.status}`);
      }
      
      const data = await response.json();
      
      return {
        content: [{
          type: 'text',
          text: `Created ${texts.length} embedding(s). Dimension: ${data.embedding?.length || 'unknown'}\n\nRaw response available for processing.`
        }],
        // Include raw data for programmatic use
        data: data
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: `Embedding error: ${error.message}`
        }],
        isError: true
      };
    }
  }
);

// ============================================================================
// Resource: Orchestrator Health
// ============================================================================

server.resource(
  'orchestrator://health',
  {
    description: 'Current health status of the orchestrator and all backends',
    mimeType: 'application/json'
  },
  async () => {
    try {
      const response = await fetch(`${ORCHESTRATOR_URL}/`);
      const data = await response.json();
      
      return {
        content: [{
          type: 'text',
          text: JSON.stringify(data, null, 2)
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({ error: error.message })
        }]
      };
    }
  }
);

// ============================================================================
// Start the server
// ============================================================================

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  
  console.error('Hybrid AI Orchestrator MCP Server started');
  console.error(`Connecting to orchestrator at: ${ORCHESTRATOR_URL}`);
}

main().catch(console.error);
