# frozen_string_literal: true

# The base checks, the same for every plugin. Run by bin/check through `trmnlp test`.
require_relative 'support'

RSpec.describe 'Base checks' do
  let(:mocks) { TPC.mocks }
  let(:custom_fields) { TPC.custom_fields }
  let(:variables) { TPC.variables }

  # trmnlp's own: all views on og_png, og_plus, v2, v2 portrait; dark mode; API failures; every select option;
  # mocks for every request; transform error and serverless limits.
  it_behaves_like 'a publishable recipe'

  # Every device model TRMNL lists today, every view, landscape and portrait: draws, no overflow, no page error.
  describe 'every device model' do
    TRMNLP::Testing::PUBLISHABLE_RECIPE_VIEWS.product(TPC.screens).each do |view, screen|
      names = screen[:same_as]
      label = "#{names.first}#{" (+#{names.size - 1} same size)" if names.size > 1} #{screen[:orientation]}"
      it "draws the #{view} view on #{label} without overflow or page errors [#{names.join(',')}]" do
        page = trmnl.render(view:, device: screen[:device], orientation: screen[:orientation],
                            mocks:, custom_fields:, variables:)
        expect(page).to have_no_overflow.and(have_no_problems).and(have_no_leaked_text)
      end
    end
  end
end
