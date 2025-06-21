require "telegram/bot"

class TelegramMessageProcessorJob < ApplicationJob
  FOOTER = I18n.t("telegram_message_processor.footer")
  ASK_MESSAGE_PREFIX = "/ask".freeze
  WEATHER_MESSAGE_PREFIX = "/weather".freeze
  WEATHER_UNITS = [
    I18n.t("telegram_message_processor.celsius"),
    I18n.t("telegram_message_processor.fahrenheit"),
    I18n.t("telegram_message_processor.kelvin")
  ].freeze

  queue_as :default

  def perform(message_data)
    chat_id = message_data[:chat][:id]
    text = message_data[:text]
    first_name = message_data[:from][:first_name]

    token = ENV["TELEGRAM_BOT_TOKEN"]
    bot_api = Telegram::Bot::Api.new(token)
    bot_api.set_my_commands(
      commands: [
        { command: "start", description: I18n.t("telegram_message_processor.command_start") },
        { command: "stop", description: I18n.t("telegram_message_processor.command_stop") },
        { command: "help", description: I18n.t("telegram_message_processor.command_help") },
        { command: "ask", description: I18n.t("telegram_message_processor.command_ask") },
        { command: "weather", description: I18n.t("telegram_message_processor.command_weather") }
      ]
    )

    response_text =
      case text
      when "/start"
        I18n.t("telegram_message_processor.start", first_name: first_name)
      when "/stop"
        I18n.t("telegram_message_processor.stop", first_name: first_name)
      when "/help"
        I18n.t("telegram_message_processor.help", first_name: first_name)
      else
        process_custom_commands(text, chat_id, first_name, bot_api)
      end

    bot_api.send_message(chat_id: chat_id, text: response_text, parse_mode: "HTML") if response_text
  end

  private

  def process_custom_commands(text, chat_id, first_name, bot_api)
    if text.start_with?(ASK_MESSAGE_PREFIX)
      process_ask_command(text, first_name)
    elsif text.start_with?(WEATHER_MESSAGE_PREFIX)
      process_weather_command(text, chat_id, bot_api)
    elsif WEATHER_UNITS.include?(text)
      process_weather_unit_selection(text, chat_id, bot_api)
    else
      I18n.t("telegram_message_processor.unknown", text: text)
    end
  end

  def process_ask_command(text, first_name)
    OpenaiProcessorJob
      .perform_now(message_data: text.delete_prefix(ASK_MESSAGE_PREFIX).strip)
      .concat(FOOTER % { first_name: first_name })
  end

  def process_weather_command(text, chat_id, bot_api)
    city = text.delete_prefix(WEATHER_MESSAGE_PREFIX).strip

    Rails.cache.write("weather_city_#{chat_id}", city, expires_in: 5.minutes)

    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: WEATHER_UNITS.map { |unit| [ { text: unit } ] },
      one_time_keyboard: true,
      resize_keyboard: true
    )

    bot_api.send_message(
      chat_id: chat_id,
      text: I18n.t("telegram_message_processor.choose_units"),
      reply_markup: answers
    )

    nil
  end

  def process_weather_unit_selection(text, chat_id, bot_api)
    city = Rails.cache.read("weather_city_#{chat_id}")

    if city.blank?
      bot_api.send_message(
        chat_id: chat_id,
        text: I18n.t("telegram_message_processor.city_missing")
      )
      return
    end

    units =
      case text
      when I18n.t("telegram_message_processor.celsius")
        "metric"
      when I18n.t("telegram_message_processor.fahrenheit")
        "imperial"
      else
        "standard"
      end

    weather = OpenWeatherProcessorJob.perform_now(city: city, units: units)

    Rails.cache.delete("weather_city_#{chat_id}")

    weather
  end
end
