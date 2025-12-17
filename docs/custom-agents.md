# Custom AI Agents

RadiantX includes three specialized custom agents that can be used during AI agent sessions (such as GitHub Copilot coding agent) to assist with development tasks.

## Available Agents

### Agent 006 - Backend Architecture & Infrastructure Savant

**Expertise:**
- Backend architecture and API design
- Database design and optimization
- Infrastructure-as-code (Terraform, Kubernetes)
- DevOps and CI/CD pipelines
- Scalability and reliability engineering
- Distributed systems design

**When to use:**
- Designing new backend services or APIs
- Setting up infrastructure or deployment pipelines
- Optimizing database queries and schemas
- Troubleshooting performance or reliability issues

### Agent 007 - Elite Games Developer & Coding Savant

**Expertise:**
- Game development across all major engines (Unity, Unreal, Godot)
- GDScript, C++, C#, and shader programming
- Game architecture patterns and optimization
- Procedural generation and AI systems
- Networking and multiplayer
- Physics and gameplay programming

**When to use:**
- Implementing new game features in RadiantX
- Optimizing game performance
- Working with the match engine or agent AI
- Debugging GDScript code
- Creating new tactical mechanics

### Agent 47 - Frontend UI/UX Visual Design & Accessibility Savant

**Expertise:**
- UI/UX design with pixel-perfect precision
- Accessibility (WCAG compliance, screen reader support)
- Typography, color systems, and visual hierarchy
- Animation and micro-interactions
- Progressive enhancement and performance
- Semantic HTML, CSS, and JavaScript

**When to use:**
- Designing or improving user interfaces
- Ensuring accessibility compliance
- Creating smooth animations and transitions
- Optimizing frontend performance

## How Custom Agents Work

Custom agents are defined in `.github/agents/` with the following file naming convention:
```
.github/agents/<agent-name>.agent.md
```

Each agent file contains:
1. **YAML Frontmatter** - Configuration including name, description, and available tools
2. **Markdown Body** - Detailed instructions, expertise, and persona for the agent

### Configuration Format

```markdown
---
name: "Agent Name"
description: "Brief description of the agent's expertise"
tools: ['read', 'search', 'edit', 'bash']
aliases: ["Alternative Name"]
---

# Agent Instructions

Detailed persona and instructions...
```

## Using Custom Agents

When working with AI agent sessions (like GitHub Copilot coding agent), the custom agents are automatically available as tools. The AI orchestrator will delegate specialized tasks to the appropriate agent based on the task requirements.

### Example Scenarios

1. **Need to add a new tactical mechanic?**
   - Agent 007 can implement the game logic in GDScript

2. **Setting up a new CI/CD workflow?**
   - Agent 006 can design and implement the pipeline

3. **Improving the UI or accessibility?**
   - Agent 47 can design and implement interface improvements

## Agent Files

| Agent | File Location |
|-------|---------------|
| Agent 006 | `.github/agents/agent-006.agent.md` |
| Agent 007 | `.github/agents/agent-007.agent.md` |
| Agent 47 | `.github/agents/agent-47.agent.md` |

## The Trio

These three agents form a complementary team covering the full development stack:

- **Agent 47** handles the frontend experience—UI/UX, accessibility, visual design
- **Agent 007** handles game development—engines, gameplay, procedural systems
- **Agent 006** handles the backend foundation—APIs, databases, infrastructure, scalability

Together, they provide comprehensive assistance for any development task in RadiantX.
