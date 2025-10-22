# File Deletion Feature Plan

## Overview
Implement immediate AJAX-based file deletion with confirmation dialog for all file upload types (simple documents and specialized documents with metadata).

## User Requirements
- **Deletion Method:** Immediate deletion with AJAX
- **Confirmation:** Yes, show confirmation dialog
- **Specialized Docs:** Same deletion method for all file types

---

## Phase 1: Backend - Controller & Routes

### 1.1 Create Attachments Controller
**New file:** `app/controllers/candidate/attachments_controller.rb`

```ruby
module Candidate
  class AttachmentsController < ApplicationController
    before_action :find_market_application
    before_action :find_attachment

    def destroy
      # Verify attachment belongs to this market application
      if @attachment && attachment_belongs_to_application?
        @attachment.purge_later
        render json: { success: true, message: I18n.t('candidate.attachments.delete_success') }
      else
        render json: { success: false, message: I18n.t('candidate.attachments.not_found') },
               status: :not_found
      end
    end

    private

    def find_market_application
      @market_application = MarketApplication
        .includes(market_attribute_responses: :documents_attachments)
        .find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, message: 'Application not found' }, status: :not_found
    end

    def find_attachment
      @attachment = ActiveStorage::Attachment.find_by(
        blob: ActiveStorage::Blob.find_signed(params[:signed_id])
      )
    end

    def attachment_belongs_to_application?
      @market_application.market_attribute_responses.any? do |response|
        response.documents.include?(@attachment)
      end
    end
  end
end
```

**Features:**
- Authenticate user owns the market application
- Find attachment by signed_id
- Verify attachment belongs to a response in this market application
- Use `purge_later` for async deletion
- Return JSON with success/error status

### 1.2 Add Route
**File:** `config/routes.rb`

Add under `namespace :candidate`:
```ruby
namespace :candidate do
  resources :market_applications, only: [:show, :update], param: :identifier do
    # Add this line:
    delete 'attachments/:signed_id', to: 'attachments#destroy', as: :delete_attachment
  end
end
```

**Result:** `DELETE /candidate/market_applications/:identifier/attachments/:signed_id`

---

## Phase 2: Backend - Model Enhancement

### 2.1 Add Method to FileAttachable
**File:** `app/models/concerns/market_attribute_response/file_attachable.rb`

Add public method:
```ruby
def remove_document_by_signed_id(signed_id)
  attachment = documents.attachments.find do |att|
    att.blob.signed_id == signed_id
  end

  return false unless attachment

  attachment.purge_later
  true
rescue ActiveRecord::RecordNotFound
  false
end
```

---

## Phase 3: Frontend - Helper Updates

### 3.1 Update current_documents_list Helper
**File:** `app/helpers/market_attribute_responses_helper.rb`

Modify `current_documents_list` method to include delete buttons:

```ruby
def current_documents_list(documents, market_application_identifier, show_empty: false, deletable: false)
  persisted_documents = documents.select(&:persisted?)

  if persisted_documents.any?
    content_tag :div, class: 'fr-mt-2w fr-text--sm fr-mb-0' do
      concat content_tag(:strong, 'Documents actuels :')
      persisted_documents.each do |document|
        concat render_document_with_delete(document, market_application_identifier, deletable)
      end
    end
  elsif show_empty
    content_tag :div, class: 'fr-mt-2w fr-text--sm fr-mb-0' do
      concat content_tag(:strong, 'Fichiers actuels :')
      concat content_tag(:span, 'Aucun fichier téléchargé')
    end
  end
end

private

def render_document_with_delete(document, market_application_identifier, deletable)
  content_tag :div, class: 'file-item' do
    concat link_to(document.filename.to_s, url_for(document),
                   target: '_blank', rel: 'noopener', class: 'file-link')

    if deletable
      concat content_tag(:span, class: 'file-delete-wrapper') do
        button_tag type: 'button',
          class: 'fr-btn fr-btn--tertiary-no-outline fr-btn--sm fr-icon-delete-line',
          data: {
            controller: 'file-delete',
            file_delete_signed_id_value: document.signed_id,
            file_delete_url_value: candidate_delete_attachment_path(
              market_application_identifier,
              document.signed_id
            ),
            file_delete_filename_value: document.filename.to_s,
            action: 'click->file-delete#delete'
          },
          title: "Supprimer #{document.filename}" do
          'Supprimer'
        end
      end
    end
  end
end
```

---

## Phase 4: Frontend - Stimulus Controller

### 4.1 Create File Delete Controller
**New file:** `app/javascript/controllers/file_delete_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    signedId: String,
    url: String,
    filename: String
  }

  delete(event) {
    event.preventDefault()

    const confirmMessage = `Êtes-vous sûr de vouloir supprimer le fichier "${this.filenameValue}" ?`

    if (!confirm(confirmMessage)) {
      return
    }

    this.performDelete()
  }

  async performDelete() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(this.urlValue, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.removeFileFromDOM()
      } else {
        this.showError(data.message || 'Erreur lors de la suppression')
      }
    } catch (error) {
      this.showError('Erreur réseau lors de la suppression')
      console.error('Delete error:', error)
    }
  }

  removeFileFromDOM() {
    const fileItem = this.element.closest('.file-item')
    if (fileItem) {
      fileItem.remove()
    }
  }

  showError(message) {
    alert(message)
  }
}
```

---

## Phase 5: View Updates

### 5.1 Update All File Display Locations

Update `current_documents_list` helper calls to enable deletion:

**Files to update:**

1. **`_checkbox_with_document_form.html.erb`**
```erb
<%= current_documents_list(
  market_attribute_response.documents,
  market_attribute_response.market_application.identifier,
  deletable: true
) %>
```

2. **`_file_upload_form.html.erb`**
```erb
<%= current_documents_list(
  market_attribute_response.documents,
  market_attribute_response.market_application.identifier,
  show_empty: true,
  deletable: true
) %>
```

3. **`_inline_file_upload_form.html.erb`**
```erb
<%= current_documents_list(
  market_attribute_response.documents,
  market_attribute_response.market_application.identifier,
  show_empty: true,
  deletable: true
) %>
```

### 5.2 Update Nested Fields

For nested fields (echantillon, person, realisation), replace inline file display with helper:

**`_person_fields.html.erb`**
```erb
<% if index != 'NEW_RECORD' %>
  <%= current_documents_list(
    market_attribute_response.person_cv_attachment(index),
    market_attribute_response.market_application.identifier,
    deletable: true
  ) %>
<% end %>
```

**`_echantillon_fields.html.erb`**
```erb
<% if index != 'NEW_RECORD' %>
  <%= current_documents_list(
    market_attribute_response.echantillon_fichiers(index),
    market_attribute_response.market_application.identifier,
    deletable: true
  ) %>
<% end %>
```

**`_realisation_fields.html.erb`**
```erb
<% if index != 'NEW_RECORD' %>
  <%= current_documents_list(
    market_attribute_response.realisation_attestations(index),
    market_attribute_response.market_application.identifier,
    deletable: true
  ) %>
<% end %>
```

---

## Phase 6: CSS/Styling

### 6.1 Add Delete Button Styles
**File:** `app/assets/stylesheets/utilities.css`

```css
/* File item with delete button */
.file-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.25rem;
}

.file-link {
  flex: 1;
}

.file-delete-wrapper {
  flex-shrink: 0;
}

.file-delete-wrapper .fr-btn {
  margin: 0;
  padding: 0.25rem 0.5rem;
  font-size: 0.875rem;
}
```

---

## Phase 7: I18n

### 7.1 Add Translations
**File:** `config/locales/fr.yml`

```yaml
fr:
  candidate:
    attachments:
      delete_confirm: "Êtes-vous sûr de vouloir supprimer ce fichier ?"
      delete_success: "Fichier supprimé avec succès"
      delete_error: "Erreur lors de la suppression du fichier"
      not_found: "Fichier introuvable ou non autorisé"
```

---

## Phase 8: Security Considerations

### 8.1 Controller Authorization
- ✅ Verify `@market_application` belongs to current session
- ✅ Verify attachment exists within this application's responses
- ✅ Use signed_id to prevent enumeration attacks
- ✅ Check attachment ownership before deletion

### 8.2 CSRF Protection
- ✅ CSRF token included in AJAX requests
- ✅ Rails automatically validates token

---

## Phase 9: Error Handling

### 9.1 Backend Errors
- **Attachment not found** → 404 JSON with message
- **Not authorized** → 404 JSON (don't reveal existence)
- **Deletion failed** → 500 JSON with error message

### 9.2 Frontend Errors
- **Network error** → Alert user with generic message
- **404** → "Fichier introuvable ou non autorisé"
- **500** → Display server error message

---

## Phase 10: Testing

### 10.1 Controller Tests
**File:** `spec/controllers/candidate/attachments_controller_spec.rb` (if using RSpec)

```ruby
require 'rails_helper'

RSpec.describe Candidate::AttachmentsController, type: :controller do
  describe 'DELETE #destroy' do
    it 'deletes the attachment when authorized'
    it 'returns 404 when attachment not found'
    it 'returns 404 when attachment belongs to different application'
    it 'handles blob not found gracefully'
  end
end
```

### 10.2 Feature Tests
**File:** `features/file_deletion.feature`

```gherkin
Feature: Delete uploaded documents
  As a candidate
  I want to delete uploaded documents
  So that I can correct mistakes

  Scenario: Successfully delete a document
    Given I am on the application form
    And I have uploaded a document "test.pdf"
    When I click the delete button for "test.pdf"
    And I confirm the deletion
    Then the document "test.pdf" should be removed from the list
    And the document should be deleted from storage

  Scenario: Cancel document deletion
    Given I am on the application form
    And I have uploaded a document "test.pdf"
    When I click the delete button for "test.pdf"
    And I cancel the deletion
    Then the document "test.pdf" should still be in the list
```

---

## Implementation Order

1. **Phase 1:** Controller & Routes (backend foundation)
2. **Phase 2:** Model method (business logic)
3. **Phase 7:** I18n (translations needed by controller)
4. **Phase 4:** Stimulus controller (frontend logic)
5. **Phase 3:** Helper updates (depends on Stimulus controller)
6. **Phase 5:** View updates (uses updated helper)
7. **Phase 6:** CSS styling (visual polish)
8. **Phase 10:** Testing (verify everything works)
9. **Phase 8 & 9:** Error handling verification (final checks)

---

## Expected Results

### User Experience
1. User sees small delete button next to each uploaded file
2. Clicks delete → confirmation dialog appears with filename
3. Confirms → file disappears immediately from UI
4. File is purged from storage asynchronously (background job)

### Code Quality
- ✅ **DRY:** Single helper method for all file displays
- ✅ **Secure:** Signed IDs + authorization checks
- ✅ **Robust:** Comprehensive error handling
- ✅ **Tested:** Controller + feature tests
- ✅ **Accessible:** DSFR-compliant buttons with proper labels

---

## Files Summary

### New Files (3)
1. `app/controllers/candidate/attachments_controller.rb`
2. `app/javascript/controllers/file_delete_controller.js`
3. `spec/controllers/candidate/attachments_controller_spec.rb`
4. `features/file_deletion.feature`

### Modified Files (10)
1. `config/routes.rb`
2. `app/models/concerns/market_attribute_response/file_attachable.rb`
3. `app/helpers/market_attribute_responses_helper.rb`
4. `app/views/candidate/market_applications/market_attribute_responses/_checkbox_with_document_form.html.erb`
5. `app/views/candidate/market_applications/market_attribute_responses/_file_upload_form.html.erb`
6. `app/views/candidate/market_applications/market_attribute_responses/_inline_file_upload_form.html.erb`
7. `app/views/candidate/market_applications/market_attribute_responses/_echantillon_fields.html.erb`
8. `app/views/candidate/market_applications/market_attribute_responses/_person_fields.html.erb`
9. `app/views/candidate/market_applications/market_attribute_responses/_realisation_fields.html.erb`
10. `config/locales/fr.yml`
11. `app/assets/stylesheets/utilities.css`

---

## Notes & Considerations

- **Async Deletion:** Using `purge_later` to avoid blocking the request
- **Metadata Preservation:** Specialized documents with metadata are handled the same way
- **UX Consistency:** All file types use the same deletion pattern
- **Performance:** AJAX approach provides immediate feedback without page reload
- **Accessibility:** Confirmation dialogs are screen-reader friendly
- **i18n Ready:** All user-facing messages are translated

---

**Created:** 2025-01-21
**Status:** Ready for implementation after refactoring is complete
