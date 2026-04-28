# ViewComponents - Passe Marché

This directory contains ViewComponent-based components for the Passe Marché application. ViewComponents provide a modern, testable, and maintainable approach to building reusable view logic.

## What is ViewComponent?

ViewComponent is a framework for building reusable, testable & encapsulated view components in Ruby on Rails. It's an alternative to traditional Rails partials with several advantages:

- **Testable**: Components can be unit tested in isolation
- **Encapsulated**: Logic and templates are co-located
- **Performance**: Components are faster than partials (10-100x in some cases)
- **Type Safety**: Ruby classes provide better IDE support and refactoring
- **Documentation**: Lookbook provides living documentation with previews

## Directory Structure

```
app/components/
├── market_attribute_response/
│   ├── base_component.rb                                      # Shared base class
│   ├── fields/                                                # Reusable field components
│   │   ├── file_upload_field_component.rb
│   │   └── textarea_field_component.rb
│   ├── shared/                                                # Shared utility components
│   │   ├── document_item_component.rb
│   │   └── progress_bar_component.rb
│   │
│   │   # Simple Input Components
│   ├── text_input_component.rb                                # Text input field
│   ├── textarea_component.rb                                  # Multi-line text area
│   ├── email_input_component.rb                               # Email input field
│   ├── phone_input_component.rb                               # Phone number input
│   │
│   │   # File Upload Components
│   ├── file_upload_component.rb                               # Standard file upload
│   ├── inline_file_upload_component.rb                        # Inline file upload (auto-fillable)
│   ├── inline_url_input_component.rb                          # URL input field
│   │
│   │   # Composite Input Components
│   ├── file_or_textarea_component.rb                          # File OR text choice
│   ├── checkbox_with_document_component.rb                    # Checkbox with document upload
│   ├── radio_with_file_and_text_component.rb                  # Radio with file/text options
│   │
│   │   # Financial/Workforce Components
│   ├── capacite_economique_financiere_chiffre_affaires_global_annuel_component.rb
│   ├── capacite_economique_financiere_effectifs_moyens_annuels_component.rb
│   │
│   │   # Complex Repeatable Components
│   ├── capacites_techniques_professionnelles_outillage_echantillons_component.rb
│   ├── presentation_intervenants_component.rb
│   └── realisations_livraisons_component.rb
│
├── source_badge_component.rb                                  # Badge showing data source
└── source_badge_component.html.erb

app/views/market_attribute_response/{component_name}_component/
├── _form.html.erb     # Form mode sub-template
├── _display.html.erb  # Display mode sub-template
└── _{nested}.html.erb # Optional nested field templates (for repeatable components)

spec/components/
├── market_attribute_response/
│   ├── base_component_spec.rb
│   ├── fields/
│   │   └── {field}_component_spec.rb
│   ├── shared/
│   │   └── {shared}_component_spec.rb
│   └── {component}_component_spec.rb
└── source_badge_component_spec.rb

spec/components/previews/
└── market_attribute_response/
    └── {component}_component_preview.rb  # Lookbook previews
```

## Using Components

### In Views

Components are automatically used via dynamic resolution in the main views. The system tries to load a component first, then falls back to the old partial if the component doesn't exist:

```erb
<%
  component_class = begin
    "MarketAttributeResponse::#{response.type}Component".constantize
  rescue NameError
    nil
  end
%>

<% if component_class %>
  <%= render component_class.new(market_attribute_response: response, form: form) %>
<% else %>
  <%= render "candidate/market_applications/market_attribute_responses/#{response.type.underscore}_form",
             market_attribute_response: response, form: form %>
<% end %>
```

### Direct Usage

You can also render components directly:

```erb
<%# Form mode %>
<%= render MarketAttributeResponse::TextInputComponent.new(
  market_attribute_response: @response,
  form: form
) %>

<%# Display mode %>
<%= render MarketAttributeResponse::TextInputComponent.new(
  market_attribute_response: @response,
  context: :web  # or :pdf, :buyer
) %>
```

## Component Architecture

### BaseComponent

All MarketAttributeResponse components inherit from `MarketAttributeResponse::BaseComponent`, which provides:

- **Mode Detection**: `form_mode?`, `display_mode?`
- **Source Helpers**: `manual?`, `auto?`, `manual_after_api_failure?`
- **Visibility Logic**: `show_value?` (context-aware)
- **I18n Helpers**: `field_label`, `field_description`, `auto_filled_message`
- **Attribute Access**: `market_attribute` delegate

### Component Parameters

Components accept these parameters:

```ruby
def initialize(market_attribute_response:, form: nil, context: :web)
  @market_attribute_response = market_attribute_response
  @form = form      # FormBuilder for form mode
  @context = context # :web, :pdf, or :buyer for display mode
end
```

### Form Mode vs Display Mode

**Form Mode** (when `form` is present):
- Uses `form.fields_for :market_attribute_responses` for nested attributes
- Renders input fields or hidden fields (for auto-filled data)
- Shows validation errors
- Includes required indicators

**Display Mode** (when `form` is nil):
- Shows read-only field values
- Respects context for visibility (:web/:pdf hide auto values, :buyer shows all)
- Renders source badges
- Uses custom layout classes for PDF generation

## Context-Aware Rendering

The `:context` parameter controls visibility:

- **`:web`** - Candidate web view (summary page)
  - Hides auto-filled values for privacy
  - Shows manual values

- **`:pdf`** - Candidate attestation PDF
  - Hides auto-filled values for privacy
  - Shows manual values
  - Uses PDF-specific layout classes

- **`:buyer`** - Buyer's ZIP package
  - Shows ALL values (including auto-filled)
  - Buyer needs complete information

## Testing Components

### Unit Tests (RSpec)

Components have dedicated RSpec tests using ViewComponent test helpers:

```ruby
RSpec.describe MarketAttributeResponse::TextInputComponent, type: :component do
  let(:form) { double('FormBuilder') }
  let(:response_form) { double('ResponseFormBuilder') }

  it 'renders input field in form mode' do
    response = create(:market_attribute_response_text_input, source: :manual)
    component = described_class.new(market_attribute_response: response, form: form)

    allow(form).to receive(:fields_for).and_yield(response_form)
    allow(response_form).to receive(:text_field).and_return('<input>'.html_safe)

    render_inline(component)

    expect(page).to have_css('input')
  end
end
```

### Integration Tests (Cucumber)

Components are tested end-to-end through Cucumber features that test the full candidate flow.

## Lookbook Previews

Lookbook provides a UI for viewing and documenting components. Access it at:

**Development**: http://localhost:3000/lookbook

**Sandbox**: http://sandbox-url/lookbook

**Production**: Not accessible (environment-restricted)

### Creating Previews

Previews live in `spec/components/previews/`:

```ruby
# frozen_string_literal: true

# @label Text Input Component
# @logical_path market_attribute_response
module MarketAttributeResponse
  class TextInputComponentPreview < Lookbook::Preview
    # @label Form - Manual Source
    # @display bg_color "#f6f6f6"
    def form_manual
      response = create_response(source: :manual, text: "")
      render_with_form(response)
    end

    private

    def create_response(source:, text:)
      # Create test data...
    end

    def render_with_form(response)
      # Render with FormBuilder...
    end
  end
end
```

## Creating New Components

### 1. Create Component Class

```ruby
# frozen_string_literal: true

class MarketAttributeResponse::YourTypeComponent < MarketAttributeResponse::BaseComponent
  def your_custom_method
    # Component-specific logic
  end
end
```

### 2. Create Component Template

```erb
<%# app/components/market_attribute_response/your_type_component.html.erb %>
<% if form_mode? %>
  <%= render "market_attribute_response/your_type_component/form" %>
<% else %>
  <%= render "market_attribute_response/your_type_component/display" %>
<% end %>
```

### 3. Create Sub-templates

Form template (`app/views/market_attribute_response/your_type_component/_form.html.erb`):

```erb
<%= component.form.fields_for :market_attribute_responses, component.market_attribute_response,
                                child_index: component.market_attribute_response.id do |response_form| %>
  <%= response_form.hidden_field :id %>
  <%= response_form.hidden_field :market_attribute_id %>
  <%= response_form.hidden_field :type %>

  <%# Your form fields here %>
<% end %>
```

Display template (`app/views/market_attribute_response/your_type_component/_display.html.erb`):

```erb
<div class="field-layout-container">
  <div class="field-layout-content">
    <strong><%= component.field_label %></strong>

    <% if component.show_value? %>
      <br>
      <span class="fr-text--md fr-text--mention-grey">
        <%= component.display_value %>
      </span>
    <% end %>
  </div>
</div>
```

### 4. Create Component Spec

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::YourTypeComponent, type: :component do
  # Test form mode
  # Test display mode
  # Test all variations
end
```

### 5. Create Lookbook Preview

```ruby
# frozen_string_literal: true

# @label Your Type Component
# @logical_path market_attribute_response
module MarketAttributeResponse
  class YourTypeComponentPreview < Lookbook::Preview
    # Preview methods here
  end
end
```

### 6. Delete Old Partials

After testing, remove the old partials:

```bash
git rm app/views/candidate/market_applications/market_attribute_responses/_your_type_form.html.erb
git rm app/views/candidate/market_applications/market_attribute_responses/_your_type_display.html.erb
```

## Best Practices

### DO:
- ✅ Inherit from `BaseComponent` for MarketAttributeResponse components
- ✅ Use `fields_for` for nested attributes in form mode
- ✅ Test components in isolation with RSpec
- ✅ Create Lookbook previews for visual documentation
- ✅ Use context parameter for visibility control
- ✅ Follow DSFR CSS classes (`fr-*`)
- ✅ Keep custom classes for PDF layout (`field-layout-container`)
- ✅ Extract complex logic to component methods

### DON'T:
- ❌ Put business logic in components (use services/models)
- ❌ Access instance variables directly (use parameters)
- ❌ Skip the `fields_for` wrapper in forms
- ❌ Forget to update component specs when changing templates
- ❌ Hardcode labels (use i18n helpers)
- ❌ Mix DSFR classes with custom layout classes

## CSS Classes Reference

### DSFR (French Design System)
- `fr-input`, `fr-input-group`, `fr-input--error`
- `fr-label`, `fr-label--required`
- `fr-hint-text`, `fr-error-text`
- `fr-text--sm`, `fr-text--md`, `fr-text--mention-grey`
- `fr-badge`, `fr-badge--success`, `fr-badge--warning`
- `fr-mb-2w`, `fr-mb-4w`

### Custom (PDF Generation)
- `field-layout-container` - Container for field display
- `field-layout-content` - Content wrapper for PDF

## Running Tests

```bash
# Component specs only
bundle exec rspec spec/components/

# Full test suite
bundle exec rspec
bundle exec cucumber

# Code quality
bin/rubocop app/components/ spec/components/
```

## Migration Status

All market attribute response partials have been migrated to ViewComponents:

| Category | Components | Status |
|----------|------------|--------|
| Shared | DocumentItemComponent, ProgressBarComponent | ✅ Complete |
| Fields | FileUploadFieldComponent, TextareaFieldComponent | ✅ Complete |
| Simple Inputs | TextInput, Textarea, Email, Phone | ✅ Complete |
| File Uploads | FileUpload, InlineFileUpload, InlineUrlInput | ✅ Complete |
| Composite | FileOrTextarea, CheckboxWithDocument, RadioWithFileAndText | ✅ Complete |
| Financial | ChiffreAffairesGlobalAnnuel, EffectifsMoyensAnnuels | ✅ Complete |
| Repeatable | OutillageEchantillons, PresentationIntervenants, RealisationsLivraisons | ✅ Complete |

**Legacy partials removed:**
- All `_*_form.html.erb` partials
- All `_*_display.html.erb` partials
- `shared/_progress_bar.html.erb`, `shared/_document_item.html.erb`
- `fields/_file_upload_field.html.erb`, `fields/_textarea_field.html.erb`
- `_source_badge.html.erb`

## Additional Resources

- [ViewComponent Documentation](https://viewcomponent.org/)
- [Lookbook Documentation](https://lookbook.build/)
- [DSFR Documentation](https://www.systeme-de-design.gouv.fr/)

## Questions?

Check the component specs or reach out to the development team.
