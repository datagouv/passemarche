# frozen_string_literal: true

World(Warden::Test::Helpers)
Warden.test_mode!

After do
  Warden.test_reset!
end
