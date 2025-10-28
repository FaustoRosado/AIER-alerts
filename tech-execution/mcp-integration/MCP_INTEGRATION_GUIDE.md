# Model Context Protocol (MCP) Integration Guide

## Overview

Model Context Protocol (MCP) is an open standard that allows AI applications to securely access data sources and tools. This guide shows how to integrate MCP into your capstone project for the next sprint, enhancing your AI capabilities while maintaining security.

## Table of Contents

1. [What is MCP?](#what-is-mcp)
2. [Why MCP for Your Project](#why-mcp-for-your-project)
3. [Architecture Integration](#architecture-integration)
4. [Setup and Installation](#setup-and-installation)
5. [Building Custom MCP Servers](#building-custom-mcp-servers)
6. [Security Considerations](#security-considerations)
7. [Sprint 4 Implementation Roadmap](#sprint-4-implementation-roadmap)

## What is MCP?

### The Problem MCP Solves

**Traditional AI Application:**
```
AI Model → Hardcoded data access → Direct database queries
                                → File system access
                                → API calls

Problems:
- Security risks (AI has direct access to everything)
- No audit trail
- Hard to maintain
- Difficult to test
- No standardization
```

**With MCP:**
```
AI Model → MCP Client → MCP Server → Controlled access to:
                                    → Databases (read-only)
                                    → File systems (specific paths)
                                    → APIs (with rate limiting)
                                    → Tools (sandboxed execution)

Benefits:
- Secure: MCP server controls what AI can access
- Auditable: All requests logged
- Maintainable: Standard protocol
- Testable: Mock MCP servers for testing
- Flexible: Swap data sources without changing AI code
```

### MCP Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AI Application                       │
│                   (Your medical alert system)           │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ↓ (MCP Client)
        ┌───────────────────────────────────┐
        │       MCP Protocol Layer          │
        │  (Standard JSON-RPC over stdio)   │
        └───────────────────────────────────┘
                        │
            ┌───────────┼───────────┐
            │           │           │
            ↓           ↓           ↓
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │   MCP    │  │   MCP    │  │   MCP    │
    │ Server 1 │  │ Server 2 │  │ Server 3 │
    │          │  │          │  │          │
    │Database  │  │Filesystem│  │  GitHub  │
    │ Access   │  │  Access  │  │  Access  │
    └──────────┘  └──────────┘  └──────────┘
         │             │              │
         ↓             ↓              ↓
    [RDS/DynamoDB] [Project Files] [Code Repo]
```

### Key Concepts

**MCP Server**: Provides resources and tools to AI
- Resources: Data the AI can read (files, database records, API responses)
- Tools: Actions the AI can execute (run queries, create files, call APIs)
- Prompts: Pre-defined prompt templates

**MCP Client**: Connects AI to MCP servers
- Discovers available resources and tools
- Sends requests on behalf of AI
- Handles authentication and authorization

**Transport**: Communication method
- stdio: Process communication (local)
- HTTP/SSE: Network communication (remote)

## Why MCP for Your Project

### Current Architecture Limitations

**Problem 1: AI Model Lacks Context**
```python
# Current approach
def analyze_alert(vital_signs):
    prompt = f"Analyze: HR {hr}, BP {bp}, SpO2 {spo2}"
    response = model.generate(prompt)
    return response

# AI has no access to:
# - Patient history
# - Similar past cases
# - Clinical guidelines
# - Latest research
```

**Problem 2: Manual Data Integration**
```python
# You manually fetch and format data
patient_history = db.query("SELECT * FROM patients WHERE id = ?", patient_id)
guidelines = load_file("/data/clinical_guidelines.txt")
similar_cases = search_elasticsearch(vital_signs)

# Lots of code just to prepare context
# Hard to maintain, test, and secure
```

**Problem 3: No Standardization**
```python
# Each data source needs custom code
def get_patient_data():
    # Custom database code
    
def get_guidelines():
    # Custom file reading code
    
def search_cases():
    # Custom search code

# Duplicate authentication, error handling, logging
```

### Solution: MCP Integration

**With MCP:**
```python
from mcp import Client

# AI automatically accesses all context
client = Client()
client.connect_to_servers([
    "medical-database",
    "clinical-guidelines", 
    "case-search"
])

def analyze_alert(vital_signs):
    # AI has access to all MCP resources
    response = client.generate(
        model="llama3.2:3b",
        prompt=f"Analyze alert: {vital_signs}",
        # AI can automatically:
        # - Query patient history
        # - Search guidelines
        # - Find similar cases
    )
    return response
```

**Benefits:**
- AI has rich context without manual data fetching
- Standard protocol for all data sources
- Security controls in MCP servers
- Full audit trail of AI data access
- Easy to add new data sources

### Use Cases for Sprint 4

**Use Case 1: Enhanced Alert Analysis**
```
Current: AI sees only current vital signs
With MCP: AI sees vital signs + patient history + similar cases

Example:
"82-year-old patient with HR 110, BP 140/90, SpO2 94%"

Without MCP:
"Elevated heart rate and mild hypoxia. Monitor patient."

With MCP (accessing patient history):
"Patient has COPD (baseline SpO2 92-94%). Current values consistent 
with baseline. Heart rate elevation likely pain-related given 
recent surgery. Compare to similar post-op cases in database."

Much better clinical decision support!
```

**Use Case 2: Automated Documentation**
```
MCP Server provides:
- Patient demographics
- Current vitals
- Recent interventions
- Lab results

AI generates:
- Clinical notes
- Handoff summaries
- Family communication drafts

All based on real, up-to-date data from MCP
```

**Use Case 3: Research Assistant**
```
MCP Server provides:
- Access to medical literature database
- Similar case outcomes
- Clinical trial data

AI helps:
- Find relevant research for case
- Identify treatment options
- Suggest evidence-based interventions
```

## Architecture Integration

### Hybrid Architecture with Tailscale + MCP

```
┌────────────────────────────────────────────────────────┐
│                   On-Premises                          │
│                                                         │
│  ┌──────────────┐         ┌──────────────┐           │
│  │ AI Inference │ ←─────→ │ MCP Server   │           │
│  │ (Ollama)     │         │ (Local Data) │           │
│  └──────────────┘         └──────────────┘           │
│         │                        │                     │
│         └────────┬───────────────┘                    │
│                  │                                     │
└──────────────────┼─────────────────────────────────────┘
                   │ (Tailscale Tunnel)
                   │
┌──────────────────┼─────────────────────────────────────┐
│                  │         AWS Cloud                   │
│                  ↓                                     │
│  ┌─────────────────────────┐                          │
│  │   MCP Gateway           │                          │
│  │   (API Aggregator)      │                          │
│  └─────────────────────────┘                          │
│         │          │         │                         │
│    ┌────┘          │         └────┐                   │
│    ↓               ↓              ↓                    │
│ ┌─────┐       ┌─────┐       ┌─────┐                  │
│ │ RDS │       │  S3 │       │DynamoDB                 │
│ └─────┘       └─────┘       └─────┘                  │
│                                                         │
└────────────────────────────────────────────────────────┘
```

**Communication Flow:**
1. AI inference runs on-premises (GPU server)
2. MCP servers access data sources via Tailscale
3. All communication encrypted and logged
4. No public endpoints needed
5. Full HIPAA compliance maintained

### Security Layers

```
Layer 1: Network Security (Tailscale)
- Encrypted tunnels
- ACL-based access control
- No public exposure

Layer 2: MCP Server Authentication
- API keys per server
- Role-based access control
- Request signing

Layer 3: Resource-Level Permissions
- Read-only database access
- Specific S3 bucket access
- Limited API scopes

Layer 4: Audit Logging
- All MCP requests logged
- CloudWatch integration
- Compliance reporting
```

## Setup and Installation

### Step 1: Install MCP SDK

```bash
# Node.js implementation (recommended)
npm install -g @modelcontextprotocol/sdk

# Python implementation (alternative)
pip install mcp
```

### Step 2: Install Pre-Built MCP Servers

```bash
# Filesystem server (access project files)
npm install -g @modelcontextprotocol/server-filesystem

# PostgreSQL server (database access)
npm install -g @modelcontextprotocol/server-postgres

# GitHub server (code repository access)
npm install -g @modelcontextprotocol/server-github

# Brave Search server (web search)
npm install -g @modelcontextprotocol/server-brave-search

# Slack server (team communication)
npm install -g @modelcontextprotocol/server-slack
```

### Step 3: Configure Claude Desktop (for testing)

```json
// ~/Library/Application Support/Claude/claude_desktop_config.json (macOS)
// %APPDATA%\Claude\claude_desktop_config.json (Windows)

{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/your/capstone/project"
      ]
    },
    "postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://user:pass@localhost:5432/medical_db"
      ]
    },
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

### Step 4: Test MCP Integration

```bash
# Restart Claude Desktop
# Try prompts like:

"List files in the capstone project"
# Should show project structure

"Query the medical_db database for patient count"
# Should return database statistics (no PHI)

"Search GitHub for recent security commits"
# Should show commit history
```

## Building Custom MCP Servers

### Example 1: Medical Alert History Server

```typescript
// medical-alert-server.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import pg from 'pg';

const { Pool } = pg;

// Database connection (read-only user)
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  database: 'medical_alerts',
  user: 'readonly_user',  // Read-only access!
  password: process.env.DB_PASSWORD,
  port: 5432,
});

// Create MCP server
const server = new Server(
  {
    name: "medical-alert-history",
    version: "1.0.0",
  },
  {
    capabilities: {
      resources: {},
      tools: {},
    },
  }
);

// List available resources
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: [
      {
        uri: "alert://statistics",
        name: "Alert Statistics",
        description: "Aggregated alert statistics (no PHI)",
        mimeType: "application/json",
      },
      {
        uri: "alert://patterns",
        name: "Common Alert Patterns",
        description: "Frequently occurring alert patterns",
        mimeType: "application/json",
      },
    ],
  };
});

// Read resource content
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;

  if (uri === "alert://statistics") {
    // Query database for statistics (no PHI)
    const result = await pool.query(`
      SELECT 
        priority,
        COUNT(*) as count,
        AVG(response_time_seconds) as avg_response_time
      FROM alerts
      WHERE created_at > NOW() - INTERVAL '30 days'
      GROUP BY priority
    `);

    return {
      contents: [
        {
          uri: uri,
          mimeType: "application/json",
          text: JSON.stringify(result.rows, null, 2),
        },
      ],
    };
  }

  if (uri === "alert://patterns") {
    // Query for common patterns
    const result = await pool.query(`
      SELECT 
        alert_type,
        COUNT(*) as frequency,
        AVG(severity_score) as avg_severity
      FROM alerts
      WHERE created_at > NOW() - INTERVAL '30 days'
      GROUP BY alert_type
      ORDER BY frequency DESC
      LIMIT 10
    `);

    return {
      contents: [
        {
          uri: uri,
          mimeType: "application/json",
          text: JSON.stringify(result.rows, null, 2),
        },
      ],
    };
  }

  throw new Error(`Unknown resource: ${uri}`);
});

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "search_similar_alerts",
        description: "Search for similar historical alerts based on vital signs",
        inputSchema: {
          type: "object",
          properties: {
            heart_rate: { type: "number" },
            bp_systolic: { type: "number" },
            spo2: { type: "number" },
            limit: { type: "number", default: 5 },
          },
          required: ["heart_rate", "bp_systolic", "spo2"],
        },
      },
      {
        name: "get_alert_outcome",
        description: "Get outcome statistics for similar alerts",
        inputSchema: {
          type: "object",
          properties: {
            alert_type: { type: "string" },
            severity: { type: "string" },
          },
          required: ["alert_type"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "search_similar_alerts") {
    // Search for similar alerts (no patient identifiers returned)
    const result = await pool.query(`
      SELECT 
        alert_id,
        heart_rate,
        bp_systolic,
        spo2,
        diagnosis,
        outcome,
        similarity_score
      FROM (
        SELECT 
          id as alert_id,
          heart_rate,
          bp_systolic,
          spo2,
          diagnosis,
          outcome,
          (
            ABS(heart_rate - $1) +
            ABS(bp_systolic - $2) +
            ABS(spo2 - $3)
          ) as similarity_score
        FROM historical_alerts
        WHERE patient_id IS NOT NULL  -- Only completed cases
        ORDER BY similarity_score ASC
        LIMIT $4
      ) AS similar
    `, [args.heart_rate, args.bp_systolic, args.spo2, args.limit || 5]);

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result.rows, null, 2),
        },
      ],
    };
  }

  if (name === "get_alert_outcome") {
    // Get outcome statistics
    const result = await pool.query(`
      SELECT 
        outcome,
        COUNT(*) as count,
        AVG(resolution_time_minutes) as avg_resolution_time
      FROM historical_alerts
      WHERE alert_type = $1
        AND ($2::text IS NULL OR severity = $2)
      GROUP BY outcome
    `, [args.alert_type, args.severity || null]);

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result.rows, null, 2),
        },
      ],
    };
  }

  throw new Error(`Unknown tool: ${name}`);
});

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
```

### Example 2: Clinical Guidelines Server

```python
# clinical_guidelines_server.py
import asyncio
import json
from mcp.server.models import InitializationOptions
from mcp.server import Server, NotificationOptions
from mcp.server.stdio import stdio_server
from mcp import types

# Initialize server
server = Server("clinical-guidelines")

# Clinical guidelines database (simplified)
GUIDELINES = {
    "shock": {
        "criteria": {
            "shock_index": ">0.9",
            "systolic_bp": "<90 mmHg",
            "heart_rate": ">100 bpm"
        },
        "actions": [
            "Immediate clinical assessment",
            "IV access established",
            "Fluid resuscitation protocol",
            "Continuous monitoring",
            "Notify attending physician"
        ],
        "references": [
            "ACLS Guidelines 2024",
            "Early Goal-Directed Therapy (EGDT)"
        ]
    },
    "respiratory_distress": {
        "criteria": {
            "spo2": "<92%",
            "respiratory_rate": ">24 or <10"
        },
        "actions": [
            "Supplemental oxygen",
            "Position patient upright",
            "Assess airway patency",
            "Prepare for possible intubation"
        ],
        "references": [
            "ARDS Clinical Practice Guidelines",
            "Oxygen Therapy Best Practices"
        ]
    }
}

@server.list_resources()
async def handle_list_resources() -> list[types.Resource]:
    return [
        types.Resource(
            uri=f"guideline://{condition}",
            name=f"Clinical Guideline: {condition.replace('_', ' ').title()}",
            description=f"Evidence-based guidelines for {condition}",
            mimeType="application/json"
        )
        for condition in GUIDELINES.keys()
    ]

@server.read_resource()
async def handle_read_resource(uri: str) -> str:
    condition = uri.replace("guideline://", "")
    
    if condition in GUIDELINES:
        return json.dumps(GUIDELINES[condition], indent=2)
    
    raise ValueError(f"Unknown guideline: {condition}")

@server.list_tools()
async def handle_list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="match_guideline",
            description="Match vital signs to applicable clinical guidelines",
            inputSchema={
                "type": "object",
                "properties": {
                    "shock_index": {"type": "number"},
                    "systolic_bp": {"type": "number"},
                    "heart_rate": {"type": "number"},
                    "spo2": {"type": "number"},
                    "respiratory_rate": {"type": "number"}
                },
                "required": ["systolic_bp", "heart_rate"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    if name == "match_guideline":
        matched = []
        
        # Check shock criteria
        if "shock_index" in arguments and arguments["shock_index"] > 0.9:
            matched.append("shock")
        elif "systolic_bp" in arguments and arguments["systolic_bp"] < 90:
            matched.append("shock")
        
        # Check respiratory criteria
        if "spo2" in arguments and arguments["spo2"] < 92:
            matched.append("respiratory_distress")
        
        # Return matched guidelines
        result = {
            "matched_guidelines": matched,
            "details": {condition: GUIDELINES[condition] for condition in matched}
        }
        
        return [
            types.TextContent(
                type="text",
                text=json.dumps(result, indent=2)
            )
        ]
    
    raise ValueError(f"Unknown tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="clinical-guidelines",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={}
                )
            )
        )

if __name__ == "__main__":
    asyncio.run(main())
```

### Running Custom Servers

```bash
# Compile TypeScript server
npx tsc medical-alert-server.ts

# Run server
node medical-alert-server.js

# Or add to Claude config
{
  "mcpServers": {
    "medical-alerts": {
      "command": "node",
      "args": ["/path/to/medical-alert-server.js"],
      "env": {
        "DB_HOST": "localhost",
        "DB_PASSWORD": "your_password"
      }
    },
    "clinical-guidelines": {
      "command": "python",
      "args": ["/path/to/clinical_guidelines_server.py"]
    }
  }
}
```

## Security Considerations

### 1. Read-Only Database Access

```sql
-- Create read-only user for MCP server
CREATE USER mcp_readonly WITH PASSWORD 'secure_password';

-- Grant SELECT only on specific tables
GRANT SELECT ON historical_alerts TO mcp_readonly;
GRANT SELECT ON alert_statistics TO mcp_readonly;

-- Explicitly deny PHI tables
REVOKE ALL ON patients FROM mcp_readonly;
REVOKE ALL ON patient_identifiers FROM mcp_readonly;
```

### 2. Network Security with Tailscale

```bash
# MCP server only accessible via Tailscale
# Add Tailscale tag to MCP server host
sudo tailscale up --advertise-tags=tag:mcp-server

# ACL policy
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:ai-inference"],
      "dst": ["tag:mcp-server:3000"]
    }
  ]
}
```

### 3. Request Logging

```typescript
// Log all MCP requests
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  // Log request
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    tool: request.params.name,
    arguments: request.params.arguments,
    user: request.meta?.userId,
    source_ip: request.meta?.sourceIp
  }));
  
  // Send to CloudWatch
  await cloudwatch.putLogEvents({
    logGroupName: '/mcp/audit',
    logStreamName: 'tool-calls',
    logEvents: [{
      timestamp: Date.now(),
      message: JSON.stringify(request)
    }]
  });
  
  // Process request
  // ...
});
```

### 4. Rate Limiting

```typescript
import { RateLimiter } from 'limiter';

// 10 requests per minute per client
const limiter = new RateLimiter({
  tokensPerInterval: 10,
  interval: "minute"
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const allowed = await limiter.removeTokens(1);
  
  if (!allowed) {
    throw new Error("Rate limit exceeded");
  }
  
  // Process request
  // ...
});
```

## Sprint 4 Implementation Roadmap

### Week 1: Foundation

**Day 1-2: Setup**
- Install MCP SDK
- Configure development environment
- Test pre-built servers

**Day 3-4: Custom Server Development**
- Build medical alert history server
- Build clinical guidelines server
- Test with Claude Desktop

**Day 5: Integration**
- Connect servers to AI inference
- Test end-to-end flow
- Document API

### Week 2: Enhancement

**Day 1-2: Add Data Sources**
- Integrate with RDS
- Connect to S3 for documents
- Add Elasticsearch for search

**Day 3-4: Security Hardening**
- Implement authentication
- Add rate limiting
- Setup audit logging

**Day 5: Testing**
- Security testing
- Performance testing
- Integration testing

### Week 3: Deployment

**Day 1-2: Production Deployment**
- Deploy MCP servers to AWS
- Configure Tailscale access
- Setup monitoring

**Day 3-4: Documentation**
- Write deployment guide
- Create troubleshooting docs
- Record demo video

**Day 5: Demo Preparation**
- End-to-end testing
- Performance optimization
- Prepare presentation

### Success Metrics

**Technical:**
- MCP server response time <100ms
- 99.9% uptime
- Zero security incidents
- Full audit trail

**Functional:**
- AI can access 3+ data sources via MCP
- Improved alert quality (measured by clinician feedback)
- Reduced manual data gathering time

**Educational:**
- Team understands MCP architecture
- Documented integration patterns
- Reusable for future projects

## Summary

**Key Takeaways:**

1. **MCP = Standardized AI Data Access**: No more custom integrations for each data source
2. **Security First**: MCP servers control what AI can access
3. **Better AI Output**: Rich context leads to better decisions
4. **Production Ready**: Used by companies like Anthropic, Block, Apollo

**For Sprint 4:**
- Start with 2-3 MCP servers (alerts, guidelines, search)
- Focus on security (read-only access, audit logs)
- Integrate with Tailscale for network security
- Measure improvement in AI output quality

**Next Steps:**
1. Install MCP SDK and test pre-built servers
2. Build custom server for your medical alert data
3. Integrate with your AI inference pipeline
4. Deploy and monitor

MCP is the future of AI application development. Learn it now, use it in your capstone, add it to your resume!

## References

- **MCP Specification**: https://modelcontextprotocol.io/
- **MCP SDK**: https://github.com/modelcontextprotocol/typescript-sdk
- **Pre-built Servers**: https://github.com/modelcontextprotocol/servers
- **Anthropic MCP Guide**: https://docs.anthropic.com/mcp

Build secure, maintainable AI applications with MCP!

