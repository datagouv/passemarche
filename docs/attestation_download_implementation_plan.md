# Attestation PDF Download Implementation Plan

**Project**: Voie Rapide - Fast Track  
**Feature**: Secure PDF Attestation Download System  
**Date**: 2025-08-22  
**Status**: Planning Phase (Revised with Organizer Pattern)

---

## Executive Summary

This document outlines the implementation plan for a secure PDF attestation download system that provides dual access:
- **Candidates**: Time-limited token-based access without authentication
- **Editors**: OAuth-secured API access with full authorization

The implementation follows a micro-commit strategy using the **Organizer pattern** to orchestrate the completion flow, ensuring clean separation of concerns and maintainable code.

---

## System Architecture Overview

### Security Model
```
┌─────────────────┐         ┌──────────────────┐
│    Candidate    │         │      Editor      │
└────────┬────────┘         └────────┬─────────┘
         │                           │
         │ Token-based               │ OAuth 2.0
         │ (48hr expiry)             │ (Bearer token)
         ▼                           ▼
┌─────────────────────────────────────────────┐
│          Downloads Controller               │
│                                              │
│  - Token validation      - OAuth validation │
│  - Expiry check          - Ownership check  │
│  - Download tracking     - No tracking      │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
           ┌───────────────┐
           │  PDF Storage  │
           │ /attestations/│
           └───────────────┘
```

### Data Flow with Organizer Pattern
1. **Application Completion** → **CompleteMarketApplication Organizer**:
   - MarkApplicationAsCompleted → Set timestamps
   - GenerateAttestationPdf → Create PDF
   - GenerateSecureDownloadToken → Create access token
2. **Candidate Access** → Validate token → Serve file → Track download
3. **Editor Access** → OAuth auth → Verify ownership → Serve file

---

## Key Architectural Decision: Organizer Pattern

Using the **Interactor::Organizer** pattern (already established in the codebase) to handle the complex MarketApplication completion flow. This provides:
- **Clean separation of concerns** - Each interactor has a single responsibility
- **Automatic rollback** - Failed steps automatically rollback previous ones
- **Testability** - Each component can be tested in isolation
- **Extensibility** - Easy to add new steps without modifying existing code
- **Thin models** - Business logic stays out of ActiveRecord models

---

## Implementation Phases

## Phase 1: Database Foundation

### Commit 1: Add attestation tracking fields

**Files to modify:**
- `db/migrate/[timestamp]_add_attestation_fields_to_market_applications.rb`

**Schema changes:**
```ruby
class AddAttestationFieldsToMarketApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :market_applications, :completed_at, :datetime
    add_column :market_applications, :attestation_downloaded_at, :datetime
    add_column :market_applications, :attestation_downloaded_count, :integer, default: 0
    
    add_index :market_applications, :completed_at
  end
end
```

**Rationale:** Database changes are foundational and have no dependencies. This allows other work to proceed in parallel.

---

## Phase 2: Core Interactors

### Commit 2: Create MarkApplicationAsCompleted interactor

**New file:** `app/interactors/mark_application_as_completed.rb`

**Implementation:**
```ruby
class MarkApplicationAsCompleted < ApplicationInteractor
  def call
    market_application = context.market_application
    
    if market_application.completed_at.present?
      context.fail!(message: "Application already completed")
    end
    
    market_application.update!(completed_at: Time.current)
    context.completed_at = market_application.completed_at
  end
  
  def rollback
    context.market_application.update!(completed_at: nil)
  end
end
```

**Test coverage:** `spec/interactors/mark_application_as_completed_spec.rb`
- Test successful timestamp setting
- Test rejection of already completed applications
- Test rollback functionality

### Commit 3: Create GenerateAttestationPdf interactor

**New file:** `app/interactors/generate_attestation_pdf.rb`

**Functionality:**
- Generate placeholder PDF with title "Attestation de candidature FT[identifier]"
- Save to `storage/attestations/attestation_FT[identifier].pdf`
- Add file path to context for downstream use
- Implement rollback to delete file on failure

**Test coverage:** `spec/interactors/generate_attestation_pdf_spec.rb`
- Test successful PDF creation
- Test file system errors handling
- Test rollback file deletion

### Commit 4: Create GenerateSecureDownloadToken interactor

**New file:** `app/interactors/generate_secure_download_token.rb`

**Functionality:**
- Generate time-limited signed token (48 hours)
- Use Rails.application.message_verifier
- Add token to context
- No rollback needed (tokens are stateless)

**Test coverage:** `spec/interactors/generate_secure_download_token_spec.rb`

---

## Phase 3: Organizer Implementation

### Commit 5: Create CompleteMarketApplication organizer

**New file:** `app/organizers/complete_market_application.rb`

**Implementation:**
```ruby
class CompleteMarketApplication < ApplicationOrganizer
  organize MarkApplicationAsCompleted,
           GenerateAttestationPdf,
           GenerateSecureDownloadToken
end
```

**Test coverage:** `spec/organizers/complete_market_application_spec.rb`
- Test successful completion flow
- Test rollback on PDF generation failure
- Test rollback on token generation failure
- Test context data propagation

---

## Phase 4: Model Helpers (Minimal)

### Commit 6: Add read-only helper methods to model

**File to modify:** `app/models/market_application.rb`

**New methods (read-only only):**
```ruby
def attestation_exists?
  File.exist?(attestation_file_path)
end

def attestation_file_path
  Rails.root.join('storage', 'attestations', "attestation_FT#{identifier}.pdf")
end

def attestation_download_url(token)
  Rails.application.routes.url_helpers.candidate_download_url(token: token)
end
```

**Note:** No business logic in the model - just data access helpers

---

## Phase 5: Editor Access (OAuth)

### Commit 7: Add API endpoint for editor attestation download

**File to modify:** `app/controllers/api/v1/market_applications_controller.rb`

**New action:**
```ruby
def attestation
  # Find market application
  # Verify editor ownership through public_market association
  # Serve PDF file
  # No download tracking
end
```

**Route addition:** `config/routes.rb`
```ruby
namespace :api do
  namespace :v1 do
    resources :market_applications, only: [] do
      member do
        get :attestation
      end
    end
  end
end
```

**Test coverage:** `spec/requests/api/v1/market_applications_spec.rb`
- Test successful download with valid OAuth token
- Test rejection with invalid token
- Test rejection when editor doesn't own the market

---

## Phase 6: Candidate Access

### Commit 8: Add candidate downloads controller

**New file:** `app/controllers/candidate/downloads_controller.rb`

**Implementation:**
```ruby
class Candidate::DownloadsController < ApplicationController
  def show
    # Validate token signature
    # Check expiration
    # Find and verify file
    # Serve with forced download headers
    # Log attempt for security audit
  end
end
```

**Route addition:** `config/routes.rb`
```ruby
namespace :candidate do
  get 'downloads/:token', to: 'downloads#show', as: :download
end
```

**Security measures:**
- Path validation to prevent directory traversal
- Token expiration enforcement
- Rate limiting preparation
- Audit logging

### Commit 9: Create TrackAttestationDownload interactor

**New file:** `app/interactors/track_attestation_download.rb`

**Implementation:**
```ruby
class TrackAttestationDownload < ApplicationInteractor
  def call
    market_application = context.market_application
    
    market_application.update!(
      attestation_downloaded_at: Time.current,
      attestation_downloaded_count: market_application.attestation_downloaded_count + 1
    )
  end
end
```

**Controller update:** Call interactor on successful download

**Test coverage:** `spec/interactors/track_attestation_download_spec.rb`

---

## Phase 7: Controller Integration

### Commit 10: Integrate organizer in controller

**File to modify:** `app/controllers/candidate/market_applications_controller.rb`

**Update action:**
```ruby
def update
  if @market_application.update(market_application_params)
    if step == :summary && params[:commit] == t('button.submit_summary')
      result = CompleteMarketApplication.call(
        market_application: @market_application
      )
      
      if result.success?
        session[:download_token] = result.download_token
        redirect_to candidate_sync_status_path(@market_application.identifier)
      else
        flash.now[:alert] = result.message
        render_wizard
      end
    else
      render_wizard(@market_application)
    end
  else
    render_wizard
  end
end
```

---

## Phase 8: UI Integration

### Commit 11: Update sync_status/show view with download button

**File to modify:** `app/views/buyer/sync_status/show.html.erb`

**UI elements:**
- Download button (post-submission only)
- Expiration notice (48 hours)
- Success confirmation message
- Download link display

**Styling:** Use DSFR (Design System of French Republic) components

---

## Phase 9: Final Testing and Documentation

### Commit 12: Add integration tests

**New file:** `spec/features/candidate_attestation_download_spec.rb`

**Test scenarios:**
- Complete application and download attestation
- Token expiration handling
- Editor OAuth access
- Download tracking verification

---

## Security Considerations

### Token Security
- **Algorithm**: Rails MessageVerifier with secret_key_base
- **Expiration**: 48 hours from generation
- **Content**: Minimal (application ID + timestamp)
- **Validation**: Constant-time comparison

### Access Control
- **Candidates**: Token required, no authentication
- **Editors**: OAuth 2.0 bearer token required
- **Ownership**: Editors can only access their own markets

### File Security
- **Storage**: Local filesystem (production will use S3)
- **Path validation**: Prevent directory traversal
- **File naming**: Standardized with identifier

### Audit Trail
- **Download tracking**: Who, when, how many times
- **Security logs**: Failed attempts, invalid tokens
- **Editor access**: OAuth token logs

---

## Testing Strategy

### Unit Tests
Each commit includes its own test coverage:
- Interactor specs
- Model specs
- Controller specs
- Request specs

### Integration Tests
- End-to-end candidate flow
- API integration for editors
- Token expiration scenarios

### Security Tests
- Token tampering attempts
- Expired token rejection
- Path traversal prevention
- OAuth validation

---

## Future Enhancements

### Phase 2 (Post-MVP)
1. **PDF Content Generation**
   - Replace placeholder with actual attestation content
   - Include all application data
   - Add official formatting and logos

2. **Cloud Storage**
   - Migrate to S3/Azure for production
   - Implement CDN for faster downloads
   - Add virus scanning

3. **Advanced Features**
   - Email delivery with download link
   - Multiple format support (PDF/A, signed PDFs)
   - Batch download for editors
   - Download receipts/confirmations

4. **Security Enhancements**
   - Rate limiting per IP
   - CAPTCHA for repeated attempts
   - Webhook notifications for downloads
   - Advanced audit logging with compliance reports

---

## Benefits of the Organizer Pattern

### Clean Architecture
- **Single Responsibility**: Each interactor does one thing well
- **Dependency Injection**: Easy to test with mocks
- **Business Logic Isolation**: Models stay thin

### Automatic Rollback
```ruby
# If any step fails, previous steps are automatically rolled back:
CompleteMarketApplication.call(market_application: app)
# If GenerateAttestationPdf fails:
#   → MarkApplicationAsCompleted.rollback is called
#   → completed_at is set back to nil
#   → User can retry
```

### Easy Extension
```ruby
class CompleteMarketApplication < ApplicationOrganizer
  organize MarkApplicationAsCompleted,
           GenerateAttestationPdf,
           GenerateSecureDownloadToken,
           SendConfirmationEmail,        # ← Easy to add
           NotifyEditorWebhook,          # ← Easy to add
           CreateAuditLogEntry           # ← Easy to add
end
```

---

## Commit Summary

1. **Database**: Add attestation tracking fields
2. **Interactor**: MarkApplicationAsCompleted
3. **Interactor**: GenerateAttestationPdf
4. **Interactor**: GenerateSecureDownloadToken
5. **Organizer**: CompleteMarketApplication
6. **Model**: Add minimal helper methods
7. **API**: Editor attestation endpoint
8. **Controller**: Candidate downloads controller
9. **Interactor**: TrackAttestationDownload
10. **Integration**: Update controller to use organizer
11. **UI**: Add download button to sync_status
12. **Tests**: Integration test suite

---

## Rollback Strategy

The organizer pattern provides built-in rollback:
1. Automatic rollback on failure (no manual intervention)
2. Each interactor defines its own rollback logic
3. Database fields preserved for audit trail
4. Feature can be disabled by skipping organizer call

---

## Success Metrics

### Technical Metrics
- PDF generation success rate > 99.9%
- Download success rate > 99%
- Token validation performance < 50ms
- Zero security breaches

### Business Metrics
- Candidate download rate
- Time to first download
- Support ticket reduction
- Editor adoption rate

---

## Appendix A: File Structure

```
app/
├── controllers/
│   ├── api/
│   │   └── v1/
│   │       └── market_applications_controller.rb [modified]
│   └── candidate/
│       ├── market_applications_controller.rb [modified]
│       └── downloads_controller.rb [new]
├── interactors/
│   ├── mark_application_as_completed.rb [new]
│   ├── generate_attestation_pdf.rb [new]
│   ├── generate_secure_download_token.rb [new]
│   └── track_attestation_download.rb [new]
├── organizers/
│   └── complete_market_application.rb [new]
├── models/
│   └── market_application.rb [modified - minimal changes]
└── views/
    └── buyer/
        └── sync_status/
            └── show.html.erb [modified]

spec/
├── interactors/
│   ├── mark_application_as_completed_spec.rb [new]
│   ├── generate_attestation_pdf_spec.rb [new]
│   ├── generate_secure_download_token_spec.rb [new]
│   └── track_attestation_download_spec.rb [new]
├── organizers/
│   └── complete_market_application_spec.rb [new]
├── controllers/
│   └── candidate/
│       └── downloads_controller_spec.rb [new]
├── requests/
│   └── api/
│       └── v1/
│           └── market_applications_spec.rb [modified]
└── features/
    └── candidate_attestation_download_spec.rb [new]

storage/
└── attestations/ [new directory]
    └── .gitkeep
```

---

## Appendix B: Configuration

### Environment Variables
```bash
# Token expiration in hours (default: 48)
ATTESTATION_TOKEN_EXPIRY_HOURS=48

# Storage path (default: storage/attestations)
ATTESTATION_STORAGE_PATH=storage/attestations
```

### Routes Summary
```
GET /api/v1/market_applications/:id/attestation  # Editor access (OAuth)
GET /candidate/downloads/:token                  # Candidate access (token)
```

---

## Sign-off

**Technical Lead**: _________________  
**Security Review**: _________________  
**Product Owner**: _________________  
**Date**: _________________

---

*This document is version controlled and should be updated as implementation progresses.*
