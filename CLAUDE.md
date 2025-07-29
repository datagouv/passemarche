# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Development Partnership

We're building production-quality code together. Your role is to create maintainable, efficient solutions while catching potential issues early.

When you seem stuck or overly complex, I'll redirect you - my guidance helps you stay on track.

## 🚨 CODE QUALITY STANDARDS
**ALL quality checks must pass - EVERYTHING must be ✅ GREEN!**  
No errors. No formatting issues. No linting problems. Zero tolerance.  
These are not suggestions. Fix ALL issues before continuing.

## CRITICAL WORKFLOW - ALWAYS FOLLOW THIS!

### Research → Plan → Implement
**NEVER JUMP STRAIGHT TO CODING!** Always follow this sequence:
1. **Research**: Explore the codebase, understand existing patterns
2. **Plan**: Create a detailed implementation plan and verify it with me  
3. **Implement**: Execute the plan with validation checkpoints

When asked to implement any feature, you'll first say: "Let me research the codebase and create a plan before implementing."

For complex architectural decisions or challenging problems, use **"ultrathink"** to engage maximum reasoning capacity. Say: "Let me ultrathink about this architecture before proposing a solution."

### USE MULTIPLE AGENTS!
*Leverage subagents aggressively* for better results:

* Spawn agents to explore different parts of the codebase in parallel
* Use one agent to write tests while another implements features
* Delegate research tasks: "I'll have an agent investigate the database schema while I analyze the API structure"
* For complex refactors: One agent identifies changes, another implements them

Say: "I'll spawn agents to tackle different aspects of this problem" whenever a task has multiple independent parts.

### Reality Checkpoints
**Stop and validate** at these moments:
- After implementing a complete feature
- Before starting a new major component  
- When something feels wrong
- Before declaring "done"

Run: `bin/rubocop && bundle exec rspec && bundle exec cucumber`

> Why: You can lose track of what's actually working. These checkpoints prevent cascading failures.

### 🚨 CRITICAL: Quality Check Failures Are BLOCKING
**When quality checks report ANY issues, you MUST:**
1. **STOP IMMEDIATELY** - Do not continue with other tasks
2. **FIX ALL ISSUES** - Address every ❌ issue until everything is ✅ GREEN
3. **VERIFY THE FIX** - Re-run the failed command to confirm it's fixed
4. **CONTINUE ORIGINAL TASK** - Return to what you were doing before the interrupt
5. **NEVER IGNORE** - There are NO warnings, only requirements

This includes:
- RuboCop violations (style, complexity, security)
- Test failures
- Database migration issues
- ALL other checks

Your code must be 100% clean. No exceptions.

**Recovery Protocol:**
- When interrupted by a quality check failure, maintain awareness of your original task
- After fixing all issues and verifying the fix, continue where you left off
- Use the todo list to track both the fix and your original task

## Project Overview

**Voie Rapide** (Fast Track) is a Rails 8 application that simplifies public procurement applications for small and medium enterprises (SMEs). The project aims to transform complex bidding procedures into a streamlined, user-friendly process integrated with existing procurement platforms.

### Key Features
- OAuth integration with procurement platform editors
- Document management for public tenders
- SIRET-based company identification
- PDF generation for attestations
- Multi-platform integration via popup/iframe

### Core Workflows
1. **Buyer Journey**: Procurement officers configure tenders via editor platforms
2. **Candidate Journey**: Companies submit bids using SIRET identification
3. **Document Management**: Automatic/manual document collection and validation
4. **Attestation Generation**: PDF proof of submission with official timestamps

### Important Constraints
- SIRET validation required for all candidates
- PDF-only documents in MVP version
- French language only (i18n prepared)
- No intermediate saving in v1
- Critical download flow for attestations

### Commit Message Style

Use **Conventional Commits** format:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

## Development Commands

### Setup
```bash
# Install dependencies and set up the project
bin/setup

# Install Ruby dependencies only
bundle install
```

### Development Server
```bash
# Start development server
bin/dev

# Start Rails server directly
bin/rails server
```

### Database
```bash
# Setup/prepare database
bin/rails db:prepare

# Run migrations
bin/rails db:migrate

# Reset database
bin/rails db:reset

# Load seed data
bin/rails db:seed
```

### Testing
```bash
# Run all tests (excludes system tests)
bin/rails test

# Run tests with fresh database
bin/rails test:db

# Run specific test files
bin/rails test test/models/specific_model_test.rb
bin/rails test test/controllers/specific_controller_test.rb
```

### Code Quality
```bash
# Run RuboCop linter
bin/rubocop

# Run RSpec tests
bundle exec rspec

# Run Cucumber tests
bundle exec cucumber

# Auto-fix RuboCop issues
bin/rubocop -a
```

### Asset Management
```bash
# Precompile assets
bin/rails assets:precompile

# Clear compiled assets
bin/rails assets:clobber
```

## Architecture

### Rails Application Structure
- **Module**: `VoieRapide` - main application module
- **Database**: PostgreSQL with multiple schemas:
  - Main application schema
  - Solid Cable (WebSocket connections)
  - Solid Cache (caching layer)
  - Solid Queue (background jobs)

### Key Technologies
- **Rails 8.0.2** - Core framework
- **PostgreSQL** - Primary database
- **Turbo & Stimulus** - Frontend framework (Hotwire)
- **Importmap** - JavaScript module management
- **Propshaft** - Asset pipeline
- **Solid Cable/Cache/Queue** - Database-backed Rails infrastructure

### Integration Architecture
- **OAuth Authentication** - Inter-system authentication with editors
- **Popup/iFrame Integration** - Embedded in procurement platforms
- **ZIP File Generation** - Structured document packages
- **PDF Generation** - Attestation documents with timestamps

## Rails-Specific Rules

### FORBIDDEN - NEVER DO THESE:
- **NO raw SQL** without proper sanitization - use ActiveRecord methods!
- **NO string interpolation** in SQL queries - use parameterized queries!
- **NO mass assignment** without strong parameters
- **NO N+1 queries** - use includes, preload, or eager_load
- **NO sleep()** in controllers or models - use background jobs
- **NO hardcoded secrets** - use Rails credentials or environment variables
- **NO direct model calls** in views - use helpers or decorators
- **NO logic in migrations** - keep them simple and reversible

### Required Standards:
- **Strong Parameters** for all controller actions
- **Meaningful names**: `user_id` not `id`, `create_user` not `create`
- **Early returns** to reduce nesting
- **Service objects** for complex business logic
- **Background jobs** for long-running tasks (Solid Queue)
- **Proper error handling**: Use Rails' built-in error handling
- **RESTful routes** following Rails conventions
- **Validations** on models, not just database constraints

## Implementation Standards

### Our code is complete when:
- ✅ All RuboCop rules pass with zero issues
- ✅ All tests pass  
- ✅ Feature works end-to-end
- ✅ Database migrations are reversible
- ✅ Strong parameters are properly configured

### Testing Strategy
- **Models**: Test validations, associations, and business logic
- **Controllers**: Test authorization, parameter handling, and response formats
- **Integration**: Test complete user workflows
- **System**: Test JavaScript interactions and full UI flows
- **Security**: Test authorization boundaries and input validation

### Rails Project Structure
```
app/
├── controllers/     # HTTP request handling
├── models/         # Business logic and data
├── views/          # Templates and presentation
├── helpers/        # View helpers
├── jobs/           # Background jobs
├── mailers/        # Email handling
├── services/       # Business logic services
└── decorators/     # View-specific model enhancements

config/             # Application configuration
db/                 # Database schema and migrations
test/               # Test suite
```

## Working Memory Management

### When context gets long:
- Re-read this CLAUDE.md file
- Summarize progress in a PROGRESS.md file
- Document current state before major changes

### Maintain TODO.md:
```
## Current Task
- [ ] What we're doing RIGHT NOW

## Completed  
- [x] What's actually done and tested

## Next Steps
- [ ] What comes next
```

## Problem-Solving Together

When you're stuck or confused:
1. **Stop** - Don't spiral into complex solutions
2. **Delegate** - Consider spawning agents for parallel investigation
3. **Ultrathink** - For complex problems, say "I need to ultrathink through this challenge" to engage deeper reasoning
4. **Step back** - Re-read the requirements
5. **Simplify** - The Rails way is usually the right way
6. **Ask** - "I see two approaches: [A] vs [B]. Which do you prefer?"

My insights on better approaches are valued - please ask for them!

## Security & Performance

### **Security Always**:
- Use strong parameters for all user input
- Validate all data on the server side
- Use Rails' built-in CSRF protection
- Sanitize all user-generated content
- Use parameterized queries (ActiveRecord does this automatically)
- Keep secrets in Rails credentials, not in code

### **Performance Considerations**:
- Use database indexes for frequently queried columns
- Avoid N+1 queries with proper includes
- Use fragment caching for expensive views
- Profile with rails-profiler for bottlenecks
- Use Solid Queue for background processing

## Communication Protocol

### Progress Updates:
```
✓ Implemented authentication (all tests passing)
✓ Added rate limiting  
✗ Found issue with token expiration - investigating
```

### Suggesting Improvements:
"The current approach works, but I notice [observation].
Would you like me to [specific improvement]?"

## Working Together

- This is always a feature branch - no backwards compatibility needed
- When in doubt, we choose Rails conventions over custom solutions
- **REMINDER**: If this file hasn't been referenced in 30+ minutes, RE-READ IT!

Avoid complex abstractions or "clever" code. The Rails way is probably better, and my guidance helps you stay focused on what matters.
