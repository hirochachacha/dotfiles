# Orchestrate Command - Execute plan.md with Specialized Agents

This command reads plan.md and intelligently distributes work to specialized
agents.

## Usage

1. Create a `plan.md` file with your tasks
2. Run this orchestrate command
3. The orchestrator will analyze tasks and assign them to appropriate
   specialists

## How It Works

When you run this command:

1. **Read plan.md** to understand all tasks
2. **Analyze each task** to determine the best specialist
3. **Group related tasks** that can be done in parallel
4. **Launch specialized agents** with appropriate prompts
5. **Monitor progress** and report results

## Example plan.md Format

```markdown
# Project: User Authentication System

## Tasks

1. Design database schema for users and sessions
2. Implement user registration endpoint
3. Implement login/logout endpoints
4. Add password reset functionality
5. Write unit tests for all endpoints
6. Add integration tests
7. Review code for security vulnerabilities
8. Refactor any duplicate code
9. Write API documentation
```

## Execution Strategy

The orchestrator will:

```javascript
// Analyze plan.md and determine specialists needed
const tasks = parsePlanFile("plan.md");
const taskAssignments = analyzeTasks(tasks);

// Group 1: Database design (database-architect)
Task({
  description: "Design user schema",
  prompt: `Design database schema for:
    - User authentication system
    - Session management
    - Password reset tokens
    Follow best practices for security and indexing.`,
  subagent_type: "database-architect",
});

// Group 2: Implementation (backend-developer)
Task({
  description: "Implement auth endpoints",
  prompt: `Implement these endpoints:
    - POST /register
    - POST /login
    - POST /logout
    - POST /reset-password
    Use the designed schema and follow REST best practices.`,
  subagent_type: "backend-developer",
});

// Group 3: Testing (test-writer) - waits for implementation
Task({
  description: "Write comprehensive tests",
  prompt: `Write tests for the authentication system:
    - Unit tests for each endpoint
    - Integration tests for auth flow
    - Edge cases and error conditions
    Ensure >80% coverage.`,
  subagent_type: "test-writer",
});

// Group 4: Review (code-reviewer) - runs after implementation
Task({
  description: "Security review",
  prompt: `Review the authentication implementation for:
    - Security vulnerabilities (OWASP top 10)
    - Best practices
    - Performance issues
    Focus on auth endpoints and session management.`,
  subagent_type: "code-reviewer",
});

// Group 5: Refactoring (refactorer) - runs after review
Task({
  description: "Refactor improvements",
  prompt: `Based on review feedback, refactor:
    - Remove code duplication
    - Improve error handling
    - Optimize performance
    Maintain all tests passing.`,
  subagent_type: "refactorer",
});
```

## Task Assignment Logic

The orchestrator automatically assigns specialists based on keywords:

| Keywords in Task                      | Assigned Specialist  |
| ------------------------------------- | -------------------- |
| schema, database, table, index        | database-architect   |
| implement, create, build, add feature | backend-developer    |
| frontend, UI, component, React, Vue   | frontend-developer   |
| test, testing, coverage, TDD          | test-writer          |
| review, security, audit, check        | code-reviewer        |
| refactor, optimize, improve, clean    | refactorer           |
| API, endpoint, REST, GraphQL          | api-builder          |
| document, docs, README                | documentation-writer |

## Parallel vs Sequential Execution

### Parallel (can run simultaneously):

- Database design + Documentation
- Frontend + Backend (if well-defined interfaces)
- Multiple independent features

### Sequential (must wait):

- Implementation → Testing
- Implementation → Review
- Review → Refactoring

## Advanced plan.md Format

For more control, use structured format:

```markdown
# Project: E-commerce Platform

## Phase 1: Foundation [parallel]

- [database-architect] Design product and order schemas
- [api-designer] Create OpenAPI specification
- [documentation-writer] Write architecture docs

## Phase 2: Implementation [parallel]

- [backend-developer] Implement product CRUD APIs
- [backend-developer] Implement order management
- [frontend-developer] Build product listing UI

## Phase 3: Quality [sequential]

- [test-writer] Write comprehensive test suite
- [code-reviewer] Security and performance review
- [refactorer] Apply review recommendations
```

## Execution Command

When this orchestrate command runs, it will:

1. Parse plan.md
2. Identify task types and dependencies
3. Create optimal execution strategy
4. Launch specialized agents
5. Track progress with TodoWrite
6. Report results

## Benefits Over Manual Orchestration

- **Automatic specialist selection** based on task analysis
- **Intelligent parallelization** of independent tasks
- **Proper sequencing** of dependent tasks
- **No manual worktree management**
- **Clear progress tracking**

## Required Specialists

Ensure you have these agents in `~/.claude/agents/`:

- backend-developer.md
- frontend-developer.md
- database-architect.md
- api-designer.md
- test-writer.md
- code-reviewer.md
- refactorer.md
- documentation-writer.md

## Usage Instructions

To execute your plan:

1. Create detailed plan.md with clear tasks
2. Run this orchestrate command
3. Monitor progress as specialists work
4. Review final report

The orchestrator handles all complexity - you just provide the plan!
