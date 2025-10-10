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

### Testing Guidelines

- Use RSpec expectations syntax for tests
- Test files should follow the same structure as the application
- Do not test associations and validations directly, focus on behavior
- Never use controller specs if you can use cucumber features, if controller
  specs are needed, check if you can create organizers or services to
  handle the logic

### Implementation Guidelines

- Always implement features in the following order:
  1. Implement models and their tests
  2. Implement services (preferably organizers) and their tests
  3. Implement controllers with their views
  4. Implement cucumnber features

  At each step, ensure that the tests pass before moving to the next step.

- You can ask questions about the instructions if it not clear enough or if
  you think it will help me deepen my thinking.
- Use TDD, refactor your code after each test. Use `rubocop` to check you
  code style. Make it consistent with the rest of the codebase.
- Be sure that rubocop passes before stopping your work.
- Be sure that tests you introduce pass before stopping your work.
- Authorization should be done in the controller, not in the model/services.
- Check docs/ for technical documentation if needed.

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

## Git

- When you move files, use `git mv` to keep history.
