# ADR-0001: Agentic Loop Stack

## Status

Accepted

## Context

Agentic coding becomes more reliable when execution, verification, and memory are separate layers.

## Decision

Use this stack:

- `CLAUDE.md` and rules for always-on instructions
- skills for reusable procedures
- subagents for context isolation and independent review
- hooks for deterministic enforcement
- `/loop` for recurring work during a session
- `wiki/` for durable compiled knowledge
- MCP for trusted external systems when needed

## Consequences

This adds setup overhead, but each layer has a clear job. The system should stay small enough that every file can justify its existence.

