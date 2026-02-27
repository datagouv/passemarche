# CLAUDE.md

**Passe Marché** — Rails 8 app simplifying public procurement for SMEs.

## Quality Gate

All code must pass RuboCop (`bin/rubocop -a`) and all tests before you stop working. No exceptions.

## Implementation Order

1. Models + RSpec tests
2. Services/Organizers + RSpec tests
3. Controllers + views
4. Cucumber features

Ensure tests pass at each step before moving to the next.

## Key Rules

- **TDD**: Write tests first, refactor after each test
- **Cucumber over controller specs**: Prefer cucumber features. Use controller specs only if unavoidable, and extract logic into services/organizers
- **Service objects**: Use Organizer/Interactor pattern for complex business logic
- **Authorization**: In controllers, never in models or services
- **No hardcoded secrets**: Ask me, I'll handle secrets management
- **No direct model calls in views**: Use helpers, decorators, or presenters
- **Migrations**: Keep simple and reversible
- **Git**: Use `git mv` when moving files
- **Docs**: Check `docs/` for technical documentation

## Collaboration

- Question my ideas if you see a better approach
- Ask when instructions are unclear
- When stuck: simplify, step back, or ask — don't spiral
