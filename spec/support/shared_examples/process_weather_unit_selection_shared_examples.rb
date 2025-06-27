RSpec.shared_examples "process weather unit selection" do |unit_result|
  context "when city in cache" do
    it "sends a message with the weather information" do
      expect(bot_api).to_not receive(:send_message)
      expect(OpenWeatherProcessorJob).to receive(:perform_now).with(city: "New York", units: unit_result)

      described_class.new.send(:process_weather_unit_selection, unit, chat_id, bot_api)
    end
  end
end
