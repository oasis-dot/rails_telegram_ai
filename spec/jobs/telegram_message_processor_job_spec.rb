require "rails_helper"

RSpec.describe TelegramMessageProcessorJob, type: :job do
  describe "private methods" do
    let(:bot_api) { double(Telegram::Bot::Api, send_message: true, set_my_commands: true) }
    let(:chat_id) { 12345 }
    let(:first_name) { "User" }
    let(:message_data) do
      {
        chat: { id: chat_id },
        text: message_text,
        from: { first_name: first_name }
      }
    end

    describe "#process_ask_command" do
      let(:openai_job) { class_double(OpenaiProcessorJob, perform_now: "Response") }

      subject { described_class.new.send(:process_ask_command, "/ask What is the capital of France?", "User") }

      before do
        allow(OpenaiProcessorJob).to receive(:perform_now).and_return("Response")
      end

      it { is_expected.to eq("Response\n\nHow about this, My humanoid? 😃") }
    end

    describe "#process_weather_command" do
      context "when command is /weather" do
        subject { described_class.new.send(:process_weather_command, "/weather", chat_id, bot_api) }

        it "prompts for a city input" do
          expect(bot_api).to receive(:send_message).with(
            chat_id: chat_id,
            text: I18n.t("telegram_message_processor.ask_city")
          )

          subject
        end
      end

      context "when command is /weather with a city" do
        subject { described_class.new.send(:process_weather_command, "New York", chat_id, bot_api) }

        it "sends a message with the weather information" do
          expect(bot_api).to receive(:send_message).once

          subject
        end
      end
    end

    describe "#process_city_input" do
      let(:city) { "New York" }

      subject { described_class.new.send(:process_city_input, city, chat_id, bot_api) }

      before do
        allow(Rails.cache).to receive(:write).with("weather_city_#{chat_id}", city, expires_in: 5.minutes)
        allow(Rails.cache).to receive(:delete).with("awaiting_city_#{chat_id}")
        allow(OpenWeatherProcessorJob).to receive(:perform_now).and_return("Weather data")
      end

      it "writes the city to cache and deletes awaiting city cache" do
        expect(Rails.cache).to receive(:write).with("weather_city_#{chat_id}", city, expires_in: 5.minutes)
        expect(Rails.cache).to receive(:delete).with("awaiting_city_#{chat_id}")

        subject
      end

      it "sends a message with the weather data" do
        expect(bot_api).to receive(:send_message)

        subject
      end
    end

    describe "#process_weather_unit_selection" do
      let(:unit) { "Celsius" }

      context "when city not in cache" do
        subject { described_class.new.send(:process_weather_unit_selection, unit, chat_id, bot_api) }

        it "sends a message if city in cache blank" do
          expect(bot_api).to receive(:send_message).with(
            chat_id: chat_id,
            text: I18n.t("telegram_message_processor.city_missing"),
          )

          subject
        end
      end

      context "when city in cache" do
        before do
          allow(Rails.cache).to receive(:read).with("weather_city_#{chat_id}").and_return("New York")
          allow(OpenWeatherProcessorJob).to receive(:perform_now).and_return("Weather data")
        end

        context "unit is Celsius" do
          let(:unit) { I18n.t("telegram_message_processor.celsius") }

          subject { described_class.new.send(:process_weather_unit_selection, unit, chat_id, bot_api) }

          it_behaves_like "process weather unit selection", "metric"
        end

        context "unit is Fahrenheit" do
          let(:unit) { I18n.t("telegram_message_processor.fahrenheit") }

          subject { described_class.new.send(:process_weather_unit_selection, unit, chat_id, bot_api) }

          it_behaves_like "process weather unit selection", "imperial"
        end

        context "unit is Kelvin" do
          let(:unit) { I18n.t("telegram_message_processor.kelvin") }

          subject { described_class.new.send(:process_weather_unit_selection, unit, chat_id, bot_api) }

          it_behaves_like "process weather unit selection", "standard"
        end
      end
    end

    describe "#process_custom_commands" do
      context "when command is /weather" do
        let(:text) { "/weather" }

        subject { described_class.new.send(:process_custom_commands, text, chat_id, first_name, bot_api) }

        it { is_expected.to be_nil }
      end

      context "when command is a weather unit" do
        let(:text) { I18n.t("telegram_message_processor.celsius") }

        subject { described_class.new.send(:process_custom_commands, text, chat_id, first_name, bot_api) }

        it { is_expected.to be_nil }
      end

      context "when commnmd is with awaiting city" do
        let(:text) { "New York" }

        subject { described_class.new.send(:process_custom_commands, text, chat_id, first_name, bot_api) }

        before do
          allow(Rails.cache).to receive(:read).with("awaiting_city_#{chat_id}").and_return(true)
        end

        it "processes the city input" do
          expect(bot_api).to receive(:send_message)

          subject
        end
      end
    end

    describe "#perform" do
      before do
        allow(Telegram::Bot::Api).to receive(:new).and_return(bot_api)
      end

      context "when message is /start" do
        let(:message_text) { "/start" }

        subject { described_class.new.perform(message_data) }
        it "sends a welcome message" do
          expect(bot_api).to receive(:send_message).with(
            chat_id: chat_id,
            parse_mode: "HTML",
            text: I18n.t("telegram_message_processor.start", first_name: first_name)
          )

          subject
        end
      end

      context "when message is /stop" do
        let(:message_text) { "/stop" }

        subject { described_class.new.perform(message_data) }
        it "sends a stop message" do
          expect(bot_api).to receive(:send_message).with(
            chat_id: chat_id,
            parse_mode: "HTML",
            text: I18n.t("telegram_message_processor.stop", first_name: first_name)
          )

          subject
        end
      end

      context "when message is /help" do
        let(:message_text) { "/help" }

        subject { described_class.new.perform(message_data) }
        it "sends a help message" do
          expect(bot_api).to receive(:send_message).with(
            chat_id: chat_id,
            parse_mode: "HTML",
            text: I18n.t("telegram_message_processor.help", first_name: first_name)
          )

          subject
        end
      end

      context "when message is a custom command" do
        let(:message_text) { "/ask What is the capital of France?" }

        subject { described_class.new.perform(message_data) }

        before do
          allow(OpenaiProcessorJob).to receive(:perform_now).and_return("Response")
        end

        it "processes the ask command" do
          expect(bot_api).to receive(:send_message).with(
            chat_id: chat_id,
            parse_mode: "HTML",
            text: "Response\n\nHow about this, My humanoid? 😃"
          )

          subject
        end
      end
    end
  end
end
