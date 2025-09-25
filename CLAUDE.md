# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Development Partnership

We're building production-quality code together. Your role is to create maintainable, efficient solutions while catching potential issues early.

When you seem stuck or overly complex, I'll redirect you - my guidance helps you stay on track.

## 🚨 CODE QUALITY STANDARDS
**ALL quality checks must pass - EVERYTHING must be ✅ GREEN!**  
No errors. No formatting issues. No linting problems. Zero tolerance.  
These are not suggestions. Fix ALL issues before continuing.

Your code must be 100% clean. No exceptions.

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

### Commit Message Style

Use **Conventional Commits** format:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

Commit description should explain why we are working on a specific task, what it brings to the app and not the how. The code itself is here to describe the how.

## Development Commands

### Setup
```bash
bin/setup
bundle install
```

### Development Server
```bash
bin/dev
bin/rails server
```

### Database
```bash
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:reset
bin/rails db:seed
```

### Testing
```bash
bundle exec rspec
bundle exec cucumber
```

### Code Quality
```bash
bin/rubocop -a
```

### Asset Management
```bash
bin/rails assets:precompile
```

## Architecture

### Rails Application Structure
- **Module**: `VoieRapide` - main application module
- **Database**: PostgreSQL with multiple schemas:
  - Main application schema
  - Solid Cable (WebSocket connections)
  - Solid Cache (caching layer)
  - Solid Queue (background jobs)

### Integration Architecture
- **OAuth Authentication** - Inter-system authentication with editors
- **Popup/iFrame Integration** - Embedded in procurement platforms
- **ZIP File Generation** - Structured document packages
- **PDF Generation** - Attestation documents with timestamps

## Rails-Specific Rules

### FORBIDDEN - NEVER DO THESE:
- **NO raw SQL** without proper sanitization - use ActiveRecord methods!
- **NO mass assignment** without strong parameters
- **NO N+1 queries** - use includes, preload, or eager_load
- **NO sleep()** in controllers or models - use background jobs
- **NO hardcoded secrets** - You will leave the management of secrets to me, if you need some just ask
- **NO direct model calls** in views - use helpers or decorators or presenter
- **NO logic in migrations** - keep them simple and reversible

### Required Standards:
- **Strong Parameters** for all controller actions
- **Meaningful names**: `user_id` not `id`, `create_user` not `create`
- **Early returns** to reduce nesting
- **Service objects** for complex business logic or Organizer/Interactor pattern
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

We want to keep the testing strategy minimal and yet still cover all the important part of the app. We do not want to test the rails core behavior, we want to test our business logic.

- **Models**: business logic
- **Controllers**: Test authorization, parameter handling, and response formats
- **Integration**: Test complete user workflows

## Working Memory Management

### When context gets long:
- Re-read this CLAUDE.md file
- Summarize progress in a PROGRESS.md file
- Document current state before major changes

## Problem-Solving Together

When you're stuck or confused:
1. **Stop** - Don't spiral into complex solutions
2. **Delegate** - Consider spawning agents for parallel investigation
3. **Ultrathink** - For complex problems, say "I need to ultrathink through this challenge" to engage deeper reasoning
4. **Step back** - Re-read the requirements
5. **Simplify** - The Rails way is usually the right way
6. **Ask** - "I see two approaches: [A] vs [B]. Which do you prefer?"
7. **Interrogate** - I do want you to question my ideas and to follow my command.

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

### Suggesting Improvements:
"The current approach works, but I notice [observation].
Would you like me to [specific improvement]?"

## Working Together

- This is always a feature branch - no backwards compatibility needed
- When in doubt, we choose Rails conventions over custom solutions
- We do not want to have useless comments in the code. The code should be self explanatory, if it's not, then it needs refactoring
- Always look for the "rails way" to do the job.
- **REMINDER**: If this file hasn't been referenced in 30+ minutes, RE-READ IT!

Avoid complex abstractions or "clever" code. The Rails way is probably better, and my guidance helps you stay focused on what matters.
