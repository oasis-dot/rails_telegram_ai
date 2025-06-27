RSpec.shared_examples "open weather returns correct unit" do |unit_input, unit_output|
  context "when units are #{unit_output}" do
    let(:units_input) { unit_input }

    it "returns the correct unit in the weather data" do
      expect(result).to include(unit_output)
    end
  end
end
