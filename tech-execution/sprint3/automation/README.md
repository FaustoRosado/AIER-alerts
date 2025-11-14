# Sprint 3 Automation - Structural Pattern Approach

## Design Philosophy (Based on "A Structural Pattern for Legible Software")

This automation follows the **Concepts & Synchronizations** pattern for maximum legibility and maintainability:

### Concepts (Independent Services)
Each Lambda function is a **concept** - a fully independent service with a well-defined purpose:
- `PipelineValidator` - Validates pipeline execution success/failure
- `DriftDetector` - Detects infrastructure drift from IaC
- `SecretRotator` - Handles secret rotation validation
- `AutoRemediator` - Fixes detected issues

### Synchronizations (Event-Based Rules)
EventBridge rules are **synchronizations** - granular event-based rules that mediate between concepts:
- When pipeline fails → validate → remediate
- When drift detected → analyze → fix
- When secret rotates → validate → notify

### Why This Matters
1. **Legibility**: You can SEE the flow in EventBridge and Step Functions diagrams
2. **Modularity**: Each Lambda can be understood, tested, and modified independently
3. **Transparency**: Every action is logged with provenance (what triggered what)
4. **Incrementality**: Add new automations without touching existing ones

## Directory Structure
```
automation/
├── concepts/           # Independent Lambda functions (concepts)
│   ├── pipeline-validator/
│   ├── drift-detector/
│   └── secret-rotator/
├── synchronizations/   # EventBridge rules connecting concepts
│   ├── pipeline-events.json
│   ├── drift-events.json
│   └── secret-events.json
├── orchestration/      # Step Functions showing visible workflow
│   └── incident-response.json
└── terraform/          # Infrastructure as code
    └── main.tf
```

## How to Read This Code
1. Start with `synchronizations/` - these show WHAT events trigger WHAT actions
2. Then read `concepts/` - these show HOW each action is performed
3. Finally check `orchestration/` - these show complex multi-step workflows

Every function has:
- Clear PURPOSE comment at the top
- INPUTS/OUTPUTS documented
- PRINCIPLE explanation (what it guarantees)
- Simple, linear logic with explanatory comments

