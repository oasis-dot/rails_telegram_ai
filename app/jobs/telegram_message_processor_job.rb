require "telegram/bot"

class TelegramMessageProcessorJob < ApplicationJob
  FOOTER = I18n.t("telegram_message_processor.footer")
  MESSAGE_PREFIX = "/ask"

  queue_as :default

  def perform(message_data)
    chat_id = message_data[:chat][:id]
    text = message_data[:text]
    first_name = message_data[:from][:first_name]

    token = ENV["TELEGRAM_BOT_TOKEN"]
    bot_api = Telegram::Bot::Api.new(token)

    response_text =
      case text
      when "/start"
        I18n.t("telegram_message_processor.start", first_name: first_name)
      when "/stop"
        I18n.t("telegram_message_processor.stop", first_name: first_name)
      when "/help"
        I18n.t("telegram_message_processor.help", first_name: first_name)
      else
        if text.start_with?("/ask")
          OpenaiProcessorJob
            .perform_now(message_data: text.delete_prefix(MESSAGE_PREFIX).strip)
            .concat(FOOTER % { first_name: first_name })
        else
          I18n.t("telegram_message_processor.unknown", text: text)
        end
      end

    bot_api.send_message(chat_id: chat_id, text: response_text, parse_mode: "HTML")
  end
end
