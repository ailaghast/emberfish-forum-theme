# frozen_string_literal: true

# Discourse's own smoke test: logging in, profiles and search still work
# with the theme on. Skipped parts expect core's topic list at "/", which
# the lobby replaces; emberfish_spec.rb covers that page instead.
#
# For details, see https://meta.discourse.org/t/-/361381
RSpec.describe "Core features" do
  before { upload_theme }

  it_behaves_like "having working core features", skip_examples: %i[topics likes]
end
