# Machine Reference - Zero-Trust Hybrid AI Pipeline

This document contains the correct usernames and paths for all machines in the mesh.

## Quick Reference Table

| Machine | Tailscale Hostname | SSH Username | Home Folder Path | Role |
|---------|-------------------|--------------|------------------|------|
| NEXUS | nexus | nexus | /Users/nexus | Command Center (Mac Mini M4 Pro) |
| AEGIS | aegis | aegis | C:\Users\YOUR_WIN_USER | Primary Inference (RTX 4080 Super) |
| RYZEN-AI | ryzen-ai | YOUR_SSH_USER | C:\Users\YOUR_WIN_USER | Multi-Model (128GB RAM, Ollama) |
| KALI-NEXUS | kali-nexus | kali-nexus | /home/kali-nexus | Security Tools (Kali Linux VM) |
| PHANTOM | phantom | YOUR_SSH_USER | C:\Users\YOUR_WIN_USER | Backup Command Center (Dell XPS) |

## SSH Config (for Nexus and Phantom)

Place this in `~/.ssh/config` on your command machine:

```
# Zero-Trust Hybrid AI Pipeline - SSH Configuration

Host aegis
    HostName aegis
    User aegis

Host ryzen-ai
    HostName ryzen-ai
    User YOUR_SSH_USER

Host kali-nexus
    HostName kali-nexus
    User kali-nexus

Host phantom
    HostName phantom
    User YOUR_SSH_USER

Host nexus
    HostName nexus
    User nexus
```

## SCP Commands (from Nexus)

Copy setup scripts to each machine:

```bash
# Aegis
scp ~/Projects/zero-trust-hybrid-ai/inference-nodes/aegis/setup-aegis.ps1 aegis:C:/Users/YOUR_WIN_USER/

# Ryzen-AI
scp ~/Projects/zero-trust-hybrid-ai/inference-nodes/ryzen-ai/setup-ryzen-ai.ps1 ryzen-ai:C:/Users/YOUR_WIN_USER/

# Kali-Nexus
scp ~/Projects/zero-trust-hybrid-ai/setup-scripts/setup-kali-nexus.sh kali-nexus:~/

# Phantom
scp -r ~/Projects/zero-trust-hybrid-ai phantom:C:/Users/YOUR_WIN_USER/Projects/
```

## Windows Path Notes

On Windows machines, the login username may differ from the home folder name. This happens with:

- Microsoft accounts (email becomes username, but folder keeps original name)
- Renamed user accounts
- Domain-joined machines

**Always use `$env:USERPROFILE`** in PowerShell scripts instead of constructing paths with `$env:USERNAME`.

✅ Correct: `$env:USERPROFILE\.ssh\authorized_keys`
❌ Wrong: `C:\Users\$env:USERNAME\.ssh\authorized_keys`

## SSH Key Locations

### Nexus (Mac)
```
Private: ~/.ssh/id_ed25519
Public:  ~/.ssh/id_ed25519.pub
```

### Windows Machines (Aegis, Ryzen-AI, Phantom)
```
Private: %USERPROFILE%\.ssh\id_ed25519
Public:  %USERPROFILE%\.ssh\id_ed25519.pub
Authorized: %USERPROFILE%\.ssh\authorized_keys
Admin Auth: C:\ProgramData\ssh\administrators_authorized_keys
```

### Kali-Nexus (Linux)
```
Private: ~/.ssh/id_ed25519
Public:  ~/.ssh/id_ed25519.pub
Authorized: ~/.ssh/authorized_keys
```

## Service Endpoints

| Machine | Service | Port | Health Check |
|---------|---------|------|--------------|
| NEXUS | Orchestrator | 8000 | http://localhost:8000/health |
| AEGIS | llama.cpp | 8080 | http://aegis:8080/health |
| RYZEN-AI | Ollama | 11434 | http://ryzen-ai:11434/api/tags |
| KALI-NEXUS | Security API | 8080 | http://kali-nexus:8080/health |

## Team Attribution

- **Shay (Sheniese Aracena-Baez)** - Project Lead, 3-tier routing, HIPAA compliance
- **Shifty** - Infrastructure, DevOps, distributed systems
- **Javier Acosta** - Integration, Presidio, Streamlit UI
