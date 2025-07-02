# Development Guide

## Development Workflow

**⚠️ IMPORTANT**: 
- **NEVER** consider work complete without running tests
- **MUST** fix all test failures before finishing

## Important Rules

1. **CRITICAL: Git Commit Policy**: 
   - NEVER commit unless explicitly asked by user
   - **MUST** use Conventional Commit format for all commit messages
   - Format: `<type>(<scope>): <subject>` (e.g., `feat(auth): add login validation`)
   - Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
2. **DO NOT EDIT**: Respect DO NOT EDIT comments if it exists in the file header
4. **Security**: Never commit secrets or sensitive data
