require 'rails_helper'

RSpec.describe OpenWeatherProcessorJob, type: :job do
  let(:weather_data) do
    instance_double(
      OpenWeather::Models::City::Weather,
      name: "New York",
      main: double(temp: 20, feels_like: 18),
      weather: [ double(description: "clear sky") ],
      units: units_input,
      empty?: false
    )
  end
  let(:job) { OpenWeatherProcessorJob.new }
  let(:result) { job.perform(city: "New York", units: units_input.to_s) }

  before do
    allow(OpenWeather::Client).to receive(:new).and_return(double(current_weather: weather_data))
  end

  describe "#perform" do
    let(:units_input) { :standard }

    it "returns an error message if no data is available" do
      allow(weather_data).to receive(:name).and_return(nil)

      expect(result).to eq(I18n.t("weather.could_not_retrieve"))
    end

    it_behaves_like "open weather returns correct unit", :metric, "°C"
    it_behaves_like "open weather returns correct unit", :imperial, "°F"
    it_behaves_like "open weather returns correct unit", :standard, "K"
  end
end
